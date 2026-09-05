import SwiftUI

struct ContractsView: View {
    @Bindable var model: ContractsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                if model.contracts.isEmpty {
                    ScrollView {
                        contractsHeader
                        if !model.isRefreshing {
                            ContentUnavailableView(
                                model.selectedMarket == .traditional ? "No TradFi contracts" : "No contracts available",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Tap the update time to refresh, or check your connection in Settings.")
                            )
                            .padding(.top, EditorialSpacing.section)
                        }
                    }
                } else {
                    List {
                        contractsHeader
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        HStack {
                            Text("Instrument")
                            Spacer()
                            Text("Last price / 24h")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(EditorialTheme.mutedInk)
                        .padding(.horizontal, 20)
                        .padding(.vertical, EditorialSpacing.related)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(EditorialTheme.subtleSurface)
                        .listRowSeparator(.hidden)

                        ForEach(Array(model.contracts.enumerated()), id: \.element.id) { index, contract in
                            ContractRow(rank: index + 1, contract: contract)
                                .listRowInsets(EdgeInsets(top: EditorialSpacing.row, leading: 20, bottom: EditorialSpacing.row, trailing: 20))
                                .listRowSeparatorTint(EditorialTheme.rule)
                                .listRowBackground(EditorialTheme.surface)
                                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                                .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.top, 0, for: .scrollContent)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(EditorialTheme.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var contractsHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: "Contracts", subtitle: "Binance Futures · Top 20 by 24h turnover",
                       isRefreshing: model.isRefreshing, updatedAt: model.lastUpdatedAt,
                       showsUpdateTime: true, refresh: { Task { await model.refresh() } })
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: EditorialSpacing.section) {
                    ForEach(ContractMarketFilter.allCases) { market in
                        CategoryTab(title: market.title, isSelected: model.selectedMarket == market) {
                            Task { await model.select(market) }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(EditorialTheme.paper)
    }

}

struct ContractRow: View {
    let rank: Int
    let contract: BinanceFuturesContract
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.content) {
            summaryLayout {
                HStack(alignment: .top, spacing: 10) {
                    Text("\(rank)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(EditorialTheme.mutedInk)
                        .frame(minWidth: 18, alignment: .leading)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
                        Text(contract.symbol)
                            .font(.body.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(contract.marketDisplayLabel)
                            .font(.caption)
                            .foregroundStyle(EditorialTheme.mutedInk)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: EditorialSpacing.inline) {
                    Text(price(contract.lastPrice))
                        .font(.body.monospacedDigit().weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(signedChange)
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(contract.priceChangePercent >= 0 ? EditorialTheme.positive : EditorialTheme.negative)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Last price \(price(contract.lastPrice)) \(contract.quoteAsset), 24 hour change \(signedChange)")
            }
            VStack(spacing: EditorialSpacing.related) {
                metricLayout {
                    MetricCell(label: "24h turnover", value: "\(abbreviated(contract.quoteVolume)) \(contract.quoteAsset)")
                    MetricCell(label: "24h volume", value: "\(abbreviated(contract.volume)) \(contract.baseAsset)")
                    MetricCell(label: "Amplitude", value: contract.volatilityPercent.map { "\($0.formatted(.number.precision(.fractionLength(2))))%" } ?? "—")
                }
                metricLayout {
                    MetricCell(label: "24h high", value: price(contract.highPrice))
                    MetricCell(label: "24h low", value: price(contract.lowPrice))
                    MetricCell(label: "Trades", value: abbreviated(Double(contract.count)))
                }
            }
        }
        .foregroundStyle(EditorialTheme.ink)
    }

    private var summaryLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
    }

    private var metricLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
    }

    private var signedChange: String {
        let value = contract.priceChangePercent
        return "\(value >= 0 ? "+" : "")\(value.formatted(.number.precision(.fractionLength(2))))%"
    }

    private func price(_ value: Double) -> String {
        value.formatted(.number.precision(.significantDigits(2...8)))
    }

    private func abbreviated(_ value: Double) -> String {
        value.formatted(.number.notation(.compactName).precision(.fractionLength(1)))
    }
}

private struct MetricCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
            Text(label).font(.caption).foregroundStyle(EditorialTheme.mutedInk)
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(EditorialTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
