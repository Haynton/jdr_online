// ModifierRules::HalfAboveTen: (score - 10) / 2, rounded down: 14 gives +2, 9 gives -1
export default function halfAboveTen(score) {
  return Math.floor((score - 10) / 2)
}
