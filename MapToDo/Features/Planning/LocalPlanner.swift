import Foundation

struct TravelLeg: Hashable { let from: UUID; let to: UUID }
struct PlanPreview {
 var changes: [UUID: Date] = [:]
 var conflicts: [String] = []
 var notices: [String] = []
}
enum LocalPlanner {
 static func plan(tasks: [TaskItem], travelMinutes: [TravelLeg: Int], weatherBuffers: [UUID: Int]) -> PlanPreview {
  var result = PlanPreview()
  var occupied = tasks.filter { !$0.isCompleted && !$0.isFlexible }.sorted { $0.scheduledAt < $1.scheduledAt }
  func gap(_ a: TaskItem, _ b: TaskItem) -> TimeInterval {
   Double((travelMinutes[TravelLeg(from: a.id, to: b.id)] ?? 0) + (weatherBuffers[b.id] ?? 0)) * 60
  }
  for (a,b) in zip(occupied, occupied.dropFirst()) where a.endDate.addingTimeInterval(gap(a,b)) > b.scheduledAt {
   result.conflicts.append(String(localized: "固定事项「\(a.title)」与「\(b.title)」时间或路程冲突；原时间保持不变。"))
  }
  for task in tasks.filter({ !$0.isCompleted && $0.isFlexible }).sorted(by: { $0.flexibilityEnd < $1.flexibilityEnd }) {
   var candidate = task.scheduledAt
   let duration = Double(max(1,task.durationMinutes)) * 60
   for block in occupied {
    let end = candidate.addingTimeInterval(duration)
    if end.addingTimeInterval(gap(task,block)) <= block.scheduledAt { break }
    if candidate < block.endDate.addingTimeInterval(gap(block,task)) {
     candidate = block.endDate.addingTimeInterval(gap(block,task))
    }
   }
   guard candidate.addingTimeInterval(duration) <= task.flexibilityEnd else {
    result.conflicts.append(String(localized: "「\(task.title)」在灵活窗口内无法容纳时长与路程；未调整。"))
    continue
   }
   var scheduled = task; scheduled.scheduledAt = candidate
   occupied.append(scheduled); occupied.sort { $0.scheduledAt < $1.scheduledAt }
   if candidate != task.scheduledAt { result.changes[task.id] = candidate }
  }
  return result
 }
}
