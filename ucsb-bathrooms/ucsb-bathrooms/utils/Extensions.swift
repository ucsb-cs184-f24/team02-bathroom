import Firebase

extension Timestamp {
    func formatTimestamp() -> String {
        let date = self.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
