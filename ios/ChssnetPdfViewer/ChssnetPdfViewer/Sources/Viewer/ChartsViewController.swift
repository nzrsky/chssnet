//
//  Copyright © 2024 Alex Nazarov. All rights reserved.
//

import Foundation
import UIKit
import Charts
import PDFKit
import SnapKit
import SwiftUI

final class ChartsViewController: UIViewController {

    private let data: [(Int, CFTimeInterval)]

    init(data: [Int: CFTimeInterval]) {
        self.data = data.map { ($0.key, $0.value) }.sorted(by: { $0.0 < $1.0 })
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        if #available(iOS 16, *) {
            let chartView = BarChartView(data: data)
            let hostingViewController = UIHostingController(rootView: chartView)
            addChild(hostingViewController)

            if let hostView = hostingViewController.view {
                view.addSubview(hostView)
                hostView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct BarChartResultsView: View {
    let data: [(page: Int, time: CFTimeInterval)]

    @Binding var scrollPosition: Int

    var body: some View {
        let itemsCount = data.count

        Chart {
            ForEach(data, id: \.page) {
                BarMark(
                    x: .value("Page", $0.page),
                    y: .value("Time", $0.time)
                )
            }
            .foregroundStyle(.blue)
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text("Page number")
        }
//        .chartXAxis {
//            AxisMarks(values: .automatic) {
//                AxisGridLine()
//                AxisTick()
//                AxisValueLabel { value in
//                    Text("\(Int(value))")
//                }
//            }
//        }
        //.chartScrollableAxes(.horizontal)
        //.chartXVisibleDomain(length: itemsCount)
        //.chartScrollPosition(x: $scrollPosition)
//        .chartXAxis {
//            AxisMarks(values: .automatic) {
//                AxisTick()
//                AxisGridLine()
//                AxisValueLabel(format: .number)
//            }
//        }
    }
}

@available(iOS 16.0, *)
struct BarChartView: View {
    let data: [(page: Int, time: CFTimeInterval)]

    init(data: [(page: Int, time: CFTimeInterval)] = [(0, 100), (1, 50), (2, 200)]) {
        self.data = data
    }

    @State var scrollPositionStart = 0

    var scrollPositionEnd: Int {
        data.count
    }

    var scrollPositionString: String {
        scrollPositionStart.formatted(.number)
    }

    var scrollPositionEndString: String {
        scrollPositionEnd.formatted(.number)
    }

    var body: some View {
        List {
            VStack(alignment: .leading) {
                Text("Detection time per page")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("Average \((Double(data.reduce(into: 0, { $0 += $1.time })) / Double(data.count)).rounded(), format: .number) ms")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                BarChartResultsView(data: data, scrollPosition: $scrollPositionStart)
                    .frame(height: 240)
            }
            .listRowSeparator(.hidden)
            .transaction { $0.animation = nil }
        }
        .listStyle(.plain)
    }
}
