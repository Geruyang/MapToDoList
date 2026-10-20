import Foundation
import MapKit

struct PlanningService {
 func preview(tasks: [TaskItem], mode: TravelMode) async -> PlanPreview {
  let active = tasks.filter { !$0.isCompleted }
  guard active.count <= 8 else { return PlanPreview(conflicts: [String(localized: "一次最多规划 8 项未完成事项，请先完成或移除其他事项。")], notices: []) }
  let deadline = Date().addingTimeInterval(30)
  var travel: [TravelLeg: Int] = [:]
  var buffers: [UUID:Int] = [:]
  var notices: [String] = []
  for task in active {
   if Task.isCancelled { return PlanPreview(conflicts: [String(localized: "规划已取消。")], notices: []) }
   do {
    let weather = try await PlanningTimeout.run(seconds: 3) {
     try await WeatherProvider.shared.forecast(latitude: task.latitude, longitude: task.longitude, date: task.scheduledAt)
    }
    buffers[task.id] = weather.bufferMinutes
    if weather.bufferMinutes > 0 { notices.append(String(localized: "「\(task.title)」天气缓冲 \(weather.bufferMinutes) 分钟（\(weather.condition)）。")) }
   } catch { notices.append(String(localized: "「\(task.title)」规划时段天气无法确认，未添加天气缓冲。")) }
  }
  // Every possible transition is needed when flexible tasks change order.
  for from in active {
   for to in active where from.id != to.id {
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: from.coordinate))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.coordinate))
    request.transportType = mode == .walking ? .walking : mode == .transit ? .transit : .automobile
    request.departureDate = from.endDate
    do {
     guard !Task.isCancelled else { return PlanPreview(conflicts: [String(localized: "规划已取消。")], notices: []) }
     guard Date() < deadline else { throw AIError.message(String(localized: "查询时间已到。")) }
     let directions = MKDirections(request: request)
     defer { directions.cancel() }
     let eta = try await withTaskCancellationHandler {
      try await PlanningTimeout.run(seconds: min(5, max(0.1, deadline.timeIntervalSinceNow))) { try await directions.calculateETA() }
     } onCancel: { directions.cancel() }
     directions.cancel()
     travel[TravelLeg(from: from.id, to: to.id)] = Int(ceil(eta.expectedTravelTime / 60))
    } catch {
     if Task.isCancelled { return PlanPreview(conflicts: [String(localized: "规划已取消。")], notices: []) }
     let distance = CLLocation(latitude: from.latitude, longitude: from.longitude).distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
     let speed = mode == .walking ? 70.0 : mode == .driving ? 400.0 : 250.0
     travel[TravelLeg(from: from.id, to: to.id)] = Int(ceil(distance / speed)) + 10
     notices.append(String(localized: "「\(from.title)」→「\(to.title)」路况无法确认，采用直线距离估计并加 10 分钟；实际路线可能更长。"))
    }
   }
  }
  var result = LocalPlanner.plan(tasks: tasks, travelMinutes: travel, weatherBuffers: buffers)
  result.notices = notices + [String(localized: "MapKit ETA 按原计划出发时刻查询，调整后及未来路况仍可能变化。")]
  return result
 }
}

extension PlanningService {
 static func routeMinutes(from:TaskItem,to:TaskItem,mode:TravelMode) async throws -> Int {
  let request=MKDirections.Request()
  request.source=MKMapItem(placemark:MKPlacemark(coordinate:from.coordinate))
  request.destination=MKMapItem(placemark:MKPlacemark(coordinate:to.coordinate))
  request.transportType=mode == .walking ? .walking : mode == .transit ? .transit : .automobile
  request.departureDate=from.endDate
  let directions=MKDirections(request:request)
  defer { directions.cancel() }
  return try await withTaskCancellationHandler {
   let eta=try await directions.calculateETA()
   return Int(ceil(eta.expectedTravelTime/60))
  } onCancel: { directions.cancel() }
 }
 func validateFinal(preview:PlanPreview,allTasks:[TaskItem],mode:TravelMode,dependencies:PlanningValidationDependencies = .live) async -> PlanPreview {
  guard preview.changes.count <= 8 else { return PlanPreview(conflicts:[String(localized:"一次最多发送 8 项事项。")]) }
  let context=PlanningFinalValidation.context(preview:preview,allTasks:allTasks)
  let deadline=Date().addingTimeInterval(30)
  var travel:[TravelLeg:Int]=[:]; var weather:[UUID:Int]=[:]; var result=preview
  for item in context.tasks {
   if Task.isCancelled { return PlanPreview(conflicts:[String(localized:"规划已取消。")]) }
   do {
    guard Date() < deadline else { throw URLError(.timedOut) }
    let minutes=try await PlanningTimeout.run(seconds:min(3,max(0.01,deadline.timeIntervalSinceNow))) { try await dependencies.weatherBuffer(item) }
    weather[item.id]=minutes
    if minutes > 0 { result.notices.append(String(localized:"「\(item.title)」目标时刻天气缓冲 \(minutes) 分钟。")) }
   } catch { result.notices.append(String(localized:"「\(item.title)」规划时段天气无法确认，未添加天气缓冲。")) }
  }
  for leg in context.legs {
   if Task.isCancelled { return PlanPreview(conflicts:[String(localized:"规划已取消。")]) }
   guard let from=context.tasks.first(where:{$0.id == leg.from}),let to=context.tasks.first(where:{$0.id == leg.to}) else { continue }
   do {
    guard Date() < deadline else { throw URLError(.timedOut) }
    travel[leg]=try await PlanningTimeout.run(seconds:min(5,max(0.01,deadline.timeIntervalSinceNow))) { try await dependencies.travel(from,to,mode) }
   } catch {
    let distance=CLLocation(latitude:from.latitude,longitude:from.longitude).distance(from:CLLocation(latitude:to.latitude,longitude:to.longitude))
    travel[leg]=Int(ceil(distance/(mode == .walking ? 70 : mode == .driving ? 400 : 250)))+10
    result.notices.append(String(localized:"「\(from.title)」→「\(to.title)」路况无法确认，采用直线距离估计并加 10 分钟；实际路线可能更长。"))
   }
  }
  if Task.isCancelled { return PlanPreview(conflicts:[String(localized:"规划已取消。")]) }
  return AIService.validate(preview:PlanningFinalValidation.check(preview:result,context:context,travelMinutes:travel,weatherBuffers:weather),allTasks:allTasks)
 }
}
