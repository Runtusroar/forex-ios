import SwiftUI

struct ContractsView: View {
    @Bindable var model: ContractsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                EditorialTheme.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                    content
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.contracts.isEmpty {
            ScrollView {
                contractsHeader
                EmptyContractsView(marketType: model.selectedMarket)
                    .padding(.top, 44)
                    .padding(.horizontal, 28)
            }
            .background(EditorialTheme.paper)
            .refreshable { await model.refresh() }
        } else {
            List {
                contractsHeader
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(EditorialTheme.paper)

                ForEach(Array(model.contracts.enumerated()), id: \.element.id) { index, contract in
                    ContractRow(rank: index + 1, contract: contract)
                        .listRowSeparator(.hidden)
                        .listRowBackground(EditorialTheme.paper)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(EditorialTheme.paper)
            .refreshable { await model.refresh() }
        }
    }

    private var contractsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            EditorialMasthead(section: "Contracts")
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(updatedLabel(model.lastUpdatedAt))
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.8)
                    .foregroundStyle(EditorialTheme.accent)
                Spacer()
                Text("TIMEZONE · \(EditorialDateFormatter.utcPlusEightLabel)")
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.8)
                    .foregroundStyle(EditorialTheme.accent)
            }
            Text("BINANCE FUTURES · TOP 20 BY 24H TURNOVER")
                .font(EditorialTheme.smallCaps)
                .tracking(0.8)
                .foregroundStyle(EditorialTheme.mutedInk)
            ContractMarketPicker(model: model)
                .padding(.top, 4)
            EditorialRule(weight: .strong)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(EditorialTheme.paper)
    }

    private func updatedLabel(_ date: Date?) -> String {
        guard let date else { return "UPDATED · --:--:--" }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)
        formatter.dateFormat = "HH:mm:ss"
        return "UPDATED · \(formatter.string(from: date))"
    }
}

private struct ContractMarketPicker: View {
    @Bindable var model: ContractsViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 28) {
                ForEach(ContractMarketFilter.allCases) { marketType in
                    Button {
                        Task { await model.select(marketType) }
                    } label: {
                        VStack(spacing: 6) {
                            Text(marketType.title)
                                .font(.system(.subheadline, design: .default, weight: .semibold))
                            Rectangle()
                                .fill(
                                    model.selectedMarket == marketType
                                        ? EditorialTheme.accent
                                        : Color.clear
                                )
                                .frame(height: 3)
                        }
                        .foregroundStyle(
                            model.selectedMarket == marketType
                                ? EditorialTheme.accent
                                : EditorialTheme.ink
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 38)
                    .accessibilityValue(model.selectedMarket == marketType ? "Selected" : "")
                }
            }
        }
        .background(EditorialTheme.paper)
    }
}

private struct ContractRow: View {
    let rank: Int
    let contract: BinanceFuturesContract

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("#\(rank)")
                    .font(EditorialTheme.smallCaps.monospacedDigit())
                    .tracking(0.5)
                    .foregroundStyle(EditorialTheme.accent)
                    .frame(width: 34, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(contract.symbol)
                        .font(EditorialTheme.headline(.headline, weight: .semibold))
                    Text(contractTypeLine)
                        .font(EditorialTheme.metadata)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(contract.lastPrice, format: .number.precision(.significantDigits(2...8)))
                        .font(.headline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(EditorialTheme.ink)
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
            EditorialRule()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
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

    private var contractTypeLine: String {
        let category = contract.underlyingType.isEmpty
            ? contract.marketType.uppercased()
            : "\(contract.marketType.uppercased()) / \(contract.underlyingType.uppercased())"
        return "\(category) / BINANCE USD-M \(contract.contractType) / \(contract.status)"
    }
}

private struct PercentText: View {
    let value: Double

    var body: some View {
        Text("\(value.formatted(.number.precision(.fractionLength(2))))%")
            .font(.caption.monospacedDigit().weight(.semibold))
            .foregroundStyle(value >= 0 ? Color(red: 0.08, green: 0.36, blue: 0.27) : EditorialTheme.accent)
    }
}

private struct MetricCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(EditorialTheme.smallCaps)
                .tracking(0.5)
                .foregroundStyle(EditorialTheme.mutedInk)
            Text(value)
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(EditorialTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyContractsView: View {
    let marketType: ContractMarketFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(EditorialTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("NO CONTRACTS")
                        .font(EditorialTheme.smallCaps)
                        .tracking(1.1)
                        .foregroundStyle(EditorialTheme.accent)
                    Text(title)
                        .font(EditorialTheme.headline(.title2))
                        .foregroundStyle(EditorialTheme.ink)
                }
            }
            EditorialRule(weight: .strong)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(EditorialTheme.mutedInk)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        switch marketType {
        case .traditional: "No traditional contracts"
        case .crypto: "Crypto market board unavailable"
        case .all: "Market board unavailable"
        }
    }

    private var message: String {
        switch marketType {
        case .traditional:
            "No traditional contracts were returned by Binance for this refresh. Pull to refresh or check the server connection."
        case .crypto, .all:
            "Pull to refresh, or check the API URL and key in Settings."
        }
    }
}
