//
//  ViewController.swift
//  FlexboxPlayground
//
//  Created by Masatoshi Kubode on 2020/07/09.
//  Copyright © 2020 Wantedly, Inc. All rights reserved.
//

import UIKit
import ReactorKit
import RxCocoa
import RxDataSources
import CollectionViewCenteredFlowLayout

struct Section: IdentifiableType, Equatable, AnimatableSectionModelType {
    let identity: String = "Section"
    let items: [Item]
    init(items: [Item]) {
        self.items = items
    }
    init(original: Section, items: [Item]) {
        self.items = items
    }
}

struct Item: IdentifiableType, Equatable {
    let identity: String
}

class MyReactor: Reactor {
    
    enum Action {
        case load
        case toggle(indexPath: IndexPath)
    }
    
    enum Mutation {
        case setItems(items: [Item])
    }
    
    struct State {
        var items: [Item] = []
    }
    
    var initialState: State = State()
    
    private func genRandomItems() -> [Item] {
        let current = currentState.items.count
        
        return (0...10).map { num in
            let id = num + current
            return Item(identity: "\(id) \(String(repeating: "x", count: Int.random(in: 1...10)))")
        }
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .load:
            let items = genRandomItems()
            return Observable.just(Mutation.setItems(items: items))
        case let .toggle(indexPath):
            var items = currentState.items
            let appends = genRandomItems()
            items.insert(contentsOf: appends, at: indexPath.row + 1)
            return Observable.just(Mutation.setItems(items: items))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case let .setItems(items):
            state.items = items
        }
        return state
    }
}

class Cell : UICollectionViewCell {
    private let label: UILabel = UILabel()
    var text: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        backgroundColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        [
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            ].forEach { $0.isActive = true }
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}

class ViewController: UIViewController, View {
    
    private let dataSource: RxCollectionViewSectionedAnimatedDataSource<Section> = .init(
        configureCell: { dataSource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! Cell
            cell.text = "\(item.identity)"
            return cell
    }
    )
    private lazy var layout: UICollectionViewLayout = {
        let layout = CollectionViewCenteredFlowLayout()
        layout.estimatedItemSize = CollectionViewCenteredFlowLayout.automaticSize
        return layout
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.register(Cell.self, forCellWithReuseIdentifier: "cell")
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        view.addSubview(collectionView)
        
        [
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ].forEach { $0.isActive = true }
    }
    
    var disposeBag: DisposeBag = DisposeBag()
    
    func bind(reactor: MyReactor) {
        reactor.action.onNext(.load)
        reactor.state
            .map { [Section(items: $0.items)] }
            .distinctUntilChanged()
            .do(onNext: { print($0) })
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        collectionView.rx.itemSelected
            .do(onNext: { print($0) })
            .map { MyReactor.Action.toggle(indexPath: $0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
}

