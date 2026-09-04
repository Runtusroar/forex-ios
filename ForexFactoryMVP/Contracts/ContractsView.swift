import SwiftUI

struct ContractsView: View {
    @Bindable var model: ContractsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                if model.contracts.isEmpty, !model.isRefreshing {
                    ContentUnavailableView(
                        "No contracts",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Add your server details in Settings, then pull to refresh.")
                    )
                } else {
                    List {
                        Section("Top 20 USDT Perpetuals") {
                            ForEach(Array(model.contracts.enumerated()), id: \.element.id) { index, contract in
                                ContractRow(rank: index + 1, contract: contract)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await model.refresh() }
                }
            }
            .navigationTitle("Contracts")
            .toolbar {
                if model.isRefreshing {
                    ToolbarItem(placement: .topBarTrailing) { ProgressView() }
                }
            }
        }
    }
}

private struct ContractRow: View {
    let rank: Int
    let contract: BinanceFuturesContract

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("#\(rank)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contract.symbol)
                        .font(.headline.weight(.semibold))
                    Text("\(contract.contractType) · \(contract.status)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(contract.lastPrice, format: .number.precision(.significantDigits(2...8)))
                        .font(.headline.monospacedDigit())
                    PercentText(value: contract.priceChangePercent)
                }
            }
            HStack(spacing: 0) {
                MetricCell(label: "24h Turnover", value: abbreviated(contract.quoteVolume))
                MetricCell(label: "24h Volume", value: abbreviated(contract.volume))
                MetricCell(label: "Amplitude", value: percent(contract.volatilityPercent))
            }
            HStack(spacing: 0) {
                MetricCell(label: "High", value: price(contract.highPrice))
                MetricCell(label: "Low", value: price(contract.lowPrice))
                MetricCell(label: "Trades", value: abbreviated(Double(contract.count)))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func price(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(2...8)))
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "-" }
        return "\(value.formatted(.number.precision(.fractionLength(2))))%"
    }

    private func abbreviated(_ value: Double) -> String {
        value.formatted(.number.notation(.compactName).precision(.fractionLength(1)))
    }
}

private struct PercentText: View {
    let value: Double

    var body: some View {
        Text("\(value.formatted(.number.precision(.fractionLength(2))))%")
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(value >= 0 ? .green : .red)
    }
}

private struct MetricCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit().weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
