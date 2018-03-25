//
//  WalkthroughViewController.swift
//  STM
//
//  Created by Kesi Maduka on 1/29/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class WalkthroughViewController: KZViewController {

    let getStartedButton = UIButton().with {
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.bold)
        $0.setTitleColor(RGB(255), for: .normal)
        $0.setBackgroundColor(Constants.UI.Color.tint2, forState: .normal)
        $0.setTitle("GET STARTED", for: .normal)
    }

    let pageControl = UIPageControl().with {
        $0.numberOfPages = 7
        $0.currentPage = 0
        $0.pageIndicatorTintColor = Constants.UI.Color.gray
        $0.currentPageIndicatorTintColor = Constants.UI.Color.tint2
    }

    let scrollView = UIScrollView()
    let contentView = UIView()

    let steps = [UIImageView(image: UIImage(named: "walkthroughStep1")), UIImageView(image: UIImage(named: "walkthroughStep2")), UIImageView(image: UIImage(named: "walkthroughStep3")), UIImageView(image: UIImage(named: "walkthroughStep4")), UIImageView(image: UIImage(named: "walkthroughStep5")), UIImageView(image: UIImage(named: "walkthroughStep6")), UIImageView(image: UIImage(named: "walkthroughStep7"))]

    let walkthoughBackgroundView = UIImageView(image: UIImage(named: "walkthroughBackground"))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = RGB(214, g: 214, b: 220)

        scrollView.addSubview(contentView)

        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false

        getStartedButton.addTarget(self, action: #selector(goBackAndCheck), for: UIControlEvents.touchUpInside)

        [getStartedButton, pageControl, walkthoughBackgroundView, scrollView].forEach(view.addSubview)

        for i in 0..<steps.count {
            let step = steps[i]
            step.contentMode = .scaleAspectFill
            contentView.addSubview(step)

            if i == 0 {
                step.autoPinEdge(toSuperviewEdge: .left)
            } else {
                step.autoPinEdge(.left, to: .right, of: steps[i - 1])
            }

            step.autoPinEdge(toSuperviewEdge: .top)
            step.autoPinEdge(toSuperviewEdge: .bottom)
            step.autoMatch(.height, to: .height, of: contentView)
            step.autoMatch(.width, to: .width, of: view)

            if i == (steps.count - 1) {
                step.autoPinEdge(toSuperviewEdge: .right)
            }
        }
    }

    open override var prefersStatusBarHidden: Bool {
        return true
    }

    override func setupConstraints() {
        scrollView.autoPinEdge(toSuperviewEdge: .top)
        scrollView.autoPinEdge(toSuperviewEdge: .left)
        scrollView.autoPinEdge(toSuperviewEdge: .right)

        walkthoughBackgroundView.autoMatch(.width, to: .width, of: scrollView)
        walkthoughBackgroundView.autoMatch(.height, to: .height, of: scrollView)
        walkthoughBackgroundView.autoPinEdge(toSuperviewEdge: .top)
        walkthoughBackgroundView.autoPinEdge(toSuperviewEdge: .left)

        contentView.autoMatch(.height, to: .height, of: scrollView)
        contentView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)

        pageControl.autoPinEdge(.top, to: .bottom, of: scrollView, withOffset: 15)
        pageControl.autoAlignAxis(toSuperviewAxis: .vertical)
        getStartedButton.autoPinEdge(.top, to: .bottom, of: pageControl, withOffset: 15)

        getStartedButton.autoPinEdge(toSuperviewEdge: .left)
        getStartedButton.autoPinEdge(toSuperviewEdge: .right)
        getStartedButton.autoPinEdge(toSuperviewEdge: .bottom)
        getStartedButton.autoSetDimension(.height, toSize: 50)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x / scrollView.bounds.size.width)
        pageControl.currentPage = currentPage
    }

    @objc func goBackAndCheck() {
        UserDefaults.standard.set(true, forKey: "hasSeenWalkthrough")
        goBack()
    }

}
