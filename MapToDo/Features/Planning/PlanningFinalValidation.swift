import Foundation

struct PlanningFinalContext {
 var tasks: [TaskItem]
 var legs: [TravelLeg]
}
enum PlanningFinalValidation {
 static func context(preview: PlanPreview, allTasks: [TaskItem]) -> PlanningFinalContext {
  let ordered=allTasks.filter { !$0.isCompleted }.map { item -> TaskItem in var copy=item; copy.scheduledAt=preview.changes[item.id] ?? item.scheduledAt; return copy }.sorted { $0.scheduledAt < $1.scheduledAt }
  var ids=Set<UUID>(); var legs=Set<TravelLeg>()
  for index in ordered.indices where preview.changes[ordered[index].id] != nil {
   ids.insert(ordered[index].id)
   if index > 0 { ids.insert(ordered[index-1].id); legs.insert(TravelLeg(from:ordered[index-1].id,to:ordered[index].id)) }
   if index+1 < ordered.count { ids.insert(ordered[index+1].id); legs.insert(TravelLeg(from:ordered[index].id,to:ordered[index+1].id)) }
  }
  return PlanningFinalContext(tasks:ordered.filter { ids.contains($0.id) },legs:legs.sorted { $0.from.uuidString+$0.to.uuidString < $1.from.uuidString+$1.to.uuidString })
 }
 static func check(preview: PlanPreview, context: PlanningFinalContext, travelMinutes: [TravelLeg:Int], weatherBuffers: [UUID:Int]) -> PlanPreview {
  var result=preview
  for leg in context.legs {
   guard let from=context.tasks.first(where:{$0.id == leg.from}), let to=context.tasks.first(where:{$0.id == leg.to}) else { continue }
   let buffer=max(weatherBuffers[from.id] ?? 0,weatherBuffers[to.id] ?? 0)
   let minutes=(travelMinutes[leg] ?? 0)+buffer
   if from.endDate.addingTimeInterval(Double(minutes)*60) > to.scheduledAt {
    result.conflicts.append(String(localized:"「\(from.title)」与「\(to.title)」时间或路程冲突；请重新安排。"))
   }
  }
  return result
 }
}
struct PlanningValidationDependencies {
 var weatherBuffer: (TaskItem) async throws -> Int
 var travel: (TaskItem,TaskItem,TravelMode) async throws -> Int
 static let live=PlanningValidationDependencies(weatherBuffer:{ item in
  try await WeatherProvider.shared.forecast(latitude:item.latitude,longitude:item.longitude,date:item.scheduledAt).bufferMinutes
 },travel:{ from,to,mode in try await PlanningService.routeMinutes(from:from,to:to,mode:mode) })
}
