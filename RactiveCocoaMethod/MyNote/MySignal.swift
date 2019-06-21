//
//  MySignal.swift
//  RactiveCocoaMethod
//
//  Created by chaomeng on 2019/6/3.
//  Copyright © 2019 Jacob. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

// 初步了解下ReactiveSwift的使用

//MARK:  目录
//Event
//Observer
//Signal
//SignalProducer
//Property/MutableProperty
//Action/CocoaAction
//Hello ReactiveSwift

// MARK: 1.1 Event 信息的载体（value/error）对应枚举
public enum EventDemo  {
    case value(Any)
    case failed(Error)
    case completed
    case interrupted
}

// interrupted 事件被打断，失效
// 注： 当信号发送非Value的Event时，那么信号失效 ，无效的原因可能是failed(失败), completed(寿终正寝), interrupted(早就无效了).

// MARK: 1.2 Observer 信息处理逻辑的封装

public final class ObserverDemo {
//    public typealias Action = (EventDemo) -> (Void)
//    private let _send : Action
//    
//    public init(_ action:@escaping Action) {
//        self._send = action
//    }
//    
//    public func send(_ event:EventDemo) {
//        _send(event)
//    }
////    creatSignalfunc send(valeu:Any) {
////        _send(.value(valeu))
////    }
    
    //.... 一系列send方法
}

// Observer 内部保持了一个处理Event的闭包， 初始化Observer就是在设置这个闭包，e而调用Observer。send就是在执行这个闭包
// Observer封装了Event的处理逻辑

// MARK: 1.3  Signal 将信号发出去，发送信号有四种途径 不过这个都是经过Signal实现的。
struct SignalDemo1{
    
    // Signal的实例方法
    //note: 这里的Value和Error都是泛型, 你需要在创建的时候进行指定
    //output的作用是管理信号状态并保存由订阅者提供的Observer对象(Observer._send封装了Event的处理逻辑), 而input的作用则是在接收到Event后依次执行这些被保存的Observer._send.
    //public static func pipe(disposable: Disposable? = nil) -> (output: Signal, input: Observer)
    
    //let signalTuple = Signal<Int ,NoError>.pipe()
    //let (signal, observer) = Signal<Int, NoError>.pipe()
    
    func creatSignal1() {
        
        // 创建Signal（output）和innerver（input）
        let (signal , innerObsever) = Signal<Int , NoError>.pipe()
        
        //创建Observer
        let outerObserver1 = Signal<Int ,NoError>.Observer(value: { value in
            print("did received value:\(value)")
        })
        
        let outerObserVer2 = Signal<Int , NoError>.Observer { event in
            switch event {
            case let .value(value):
                print("did received value:\(value)")
            default: break
            }
        }
        
        // 向signal中添加Observer
        signal.observe(outerObserver1)
        signal.observe(outerObserVer2)
        
        // 向signal发生信息(执行signal保存的所有Observer对象的Event处理逻辑)
        innerObsever.send(value: 1)
        innerObsever.sendCompleted()
    }
    //1)每订阅一次Signal实际上就是在向Signal中添加一个Observer对象.
    //2)即使每次订阅信号的处理逻辑都是一样的, 但它们仍然是完全不同的的两个Observer对象.
    typealias NSignal<T> = Signal<T , NoError>
    
    // 上面方法可以简写为
    //介绍主要介绍下Signal.observeValues, 这是Signal.observe的一个便利函数, 作用是创建一个只处理Value事件的Observer并添加到Signal中, 类似的还有只处理Failed事件的Signal.observeFailed和所有事件都能处理的Signal.observeResult.
    func creatSignal2()  {
        let (signal , innerObserver) = NSignal<Int>.pipe()
        
        signal.observeValues { (value) in
            print("did received value:\(value)")
        }
        
        signal.observeValues { (value) in
            print("did received value:\(value)")
        }
        
        innerObserver.send(value: 1)
        innerObserver.sendCompleted()
    }
}


// MARK: “热”信号 -- 代码示例

// 热信号并不关心订阅者的情况m，一旦有事件即会发送，
// 收到如何飞Value事件后信号便无效了，
// 事件一旦发送，所有的订阅者都能接收到。

typealias NSignal<T> = Signal<T , NoError>

class ViewModel {
    let signal : NSignal<Int>
    let innerObserver: NSignal<Int>.Observer
    
    init() {
        (signal , innerObserver) = NSignal<Int>.pipe()
    }
}

class View1 {
    func bind(viewModel:ViewModel) {
         viewModel.signal.observeValues { (value) in
            print("view1 recatived value:\(value)")
        }
    }
}

class View2 {
    func bind(viewModel : ViewModel) {
        viewModel.signal.observeValues { (value) in
            print("view2 recatived value:\(value)")
        }
    }
}

class View3 {
    func bind(viewModel : ViewModel) {
        viewModel.signal.observeValues { (value) in
            print("View3 recatived value:\(value)")
        }
        viewModel.signal.observeInterrupted {
            print("View3 received interrupted")
        }
    }
}

extension ViewController
{
    func creatSignal() {
        let view1 = View1()
        let view2 = View2()
        let view3 = View3()
        let viewModel = ViewModel()
        
        view1.bind(viewModel: viewModel) // 订阅时机早
        viewModel.innerObserver.send(value: 1)
        // 打印view1 recatived value:1
        
        view2.bind(viewModel: viewModel) // 订阅时机晚些
        viewModel.innerObserver.send(value: 2)
        viewModel.innerObserver.sendInterrupted() // 发送一个非Value事件，信号无效
        // 打印  view1 recatived value:2
        //       view2 recatived value:2
        
        view3.bind(viewModel: viewModel)  // 信号无效后才开始订阅
        viewModel.innerObserver.send(value: 3) // 信号无效后发送事件
    }
}

// MARK: 常用函数

// MARK: 1 KVO -- KVO的Reactive版本, 对于NSObject的子类可以直接使用, 对于Swift的原生类需要加上dynamic修饰.
protocol  UsedFunc {
    func signal(forkeyPath keyPath : String) -> Signal<Any? , NoError>
}

extension ViewController : UITableViewDataSource , UITableViewDelegate {
    func creatSignal1() {
        //        let custom:CustomView =  CustomView()
        //        custom.creatTableView()
        
        tableView = UITableView.init(frame: CGRect(x: 0, y: 0, width: 300, height: 600), style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .gray
        self.view.addSubview(tableView)
        
        reactive.signal(forKeyPath: "someValue").observeValues {(value) in
            print("value \(String(describing: value))")
        }
        
        tableView.reactive.signal(forKeyPath: "contentSize").observeValues { [weak self] (content   ) in
            if let contentSize = content as? CGSize , let strongself = self {
                let isHidden = contentSize.height < strongself.tableView.frame.size.height
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                    print("isHidden \(isHidden)")
                })
            }
        }
        
        tableView.reactive.signal(forKeyPath: "contentOffset").observeValues { (content)  in
            if let contentSize = content as? CGPoint {
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
                    print("contentOffset \(contentSize.y)")
                })
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "\(indexPath.row)"
        cell.textLabel?.textColor = .white
        return cell
    }
}

//MARK: 2 map -  函数

extension ViewController {
    func creatSIgnal2()  {
        let (signal , innerObserver) = NSignal<Int>.pipe()
        
        signal.map {
        return "map \($0)"
            }.observeValues { (value) in
                print(value)
        }
        
        innerObserver.send(value: 1)
        innerObserver.sendCompleted()
    }
    // 输出  map 1
}

//MARK: 3. on -- 函数 在信号发送事件和订阅者收到事件之间插入一段事件处理逻辑, 你可以把它看做map的简洁版. (这个函数的参数很多, 但默认都有给nil, 所以你只需要关心自己需要的部分即可, 比如这里我只想在Value事件间插入逻辑)

// 函数方法
//public func on(
//    event: ((Event) -> Void)? = nil,
//    failed: ((Error) -> Void)? = nil,
//    completed: (() -> Void)? = nil,
//    interrupted: (() -> Void)? = nil,
//    terminated: (() -> Void)? = nil,
//    disposed: (() -> Void)? = nil,
//    value: ((Value) -> Void)? = nil) -> Signal<Value, Error>

extension ViewController  {
    
    func  creatSignal3() {
       let (signal , innerObserver) = NSignal<Int>.pipe()
        signal.on { (value) in
            if value != 1{
                 print("on value: \(value)")
            }else{
                print("1")
            }
            }.observeValues { (value) in
                print("did recaived value: \(value)")
        }
        
        innerObserver.send(value: 1)
        innerObserver.sendCompleted()
    }
    // 输出      1
    //          did recaived value: 1
}

//MARK: 4. take(until:) -- 函数 在takeSignal发送Event之前, signal可以正常发送Event, 一旦takeSignal开始发送Event, signal就停止发送, takeSignal相当于一个停止标志位.
// 函数方法 public func take(until trigger: Signal<(), NoError>) -> Signal<Value, Error>

extension ViewController {
    func  creatSignal4() {
        let (signal , innerObserver) = NSignal<Int>.pipe()
        let (takeSignal, takeObserver) = NSignal<()>.pipe()
        
        signal.take(until: takeSignal).observeValues { (value) in
            print("received value: \(value)")
        }
        
        innerObserver.send(value: 1)
        innerObserver.send(value: 2)
        
        takeObserver.send(value: ())
        innerObserver.send(value: 3)
        
        takeObserver.sendCompleted()
        innerObserver.sendCompleted()
    }
    // 输出    received value: 1
    //        received value: 2
}

//MARK: 5 take(first:) 只取最初N次的Event. 类似的还有signal.take(last: ): 只取最后N次的Event.

// 函数方法
//public func take(first count: Int) -> Signal<Value, Error>

extension ViewController
{
    func  creatSignal5()  {
        let (signal , innerObserver) = NSignal<Int>.pipe()
        signal.take(first: 2).observeValues { (vale) in
            print("received value: \(vale)")
        }
        
        innerObserver.send(value: 4)
        innerObserver.send(value: 5)
        innerObserver.send(value: 3)
        innerObserver.send(value: 4)
        
        innerObserver.sendCompleted()
    }
    
    // 输出  received value: 4
    //      received value: 5

}

// MARK: 6 merge 把多个信号合并为一个新的信号，任何一个信号有Event的时就会这个新信号就会Event发送出来.

//函数方法
// public static func merge(_ signals: Signal<Value, Error>...) -> Signal<Value, Error>

extension ViewController {
    func creatSignal6() {
        let (signal1, innerObserver1) = NSignal<Int>.pipe()
        let (signal2, innerObserver2) = NSignal<Int>.pipe()
        let (signal3, innerObserver3) = NSignal<Int>.pipe()
        
        Signal.merge(signal1 , signal2 , signal3).observeValues { (value) in
            print("received value: \(value)")
        }
        
        innerObserver1.send(value: 1)
        innerObserver1.sendCompleted()
        
        innerObserver2.send(value: 2)
        innerObserver2.sendCompleted()
        
        innerObserver3.send(value: 3)
        innerObserver3.sendCompleted()
    }
    // 输出   received value: 1
    //       received value: 2
    //       received value: 3

}

// MARK: 7 combineLatest : 把多个信号组合为一个新信号，新信号的Event是各个信号的最新的Event的组合.
//"组合"意味着每个信号都至少有发送过一次Event, 毕竟组合的每个部分都要有值. 所以, 如果有某个信号一次都没有发送过Event, 那么这个新信号什么也不会发送, 不论其他信号发送了多少Event.新信号只会取最新的Event的来进行组合, 而不是数学意义上的组合.

// 函数方法
// public static func combineLatest<S: Sequence>(_ signals: S) -> Signal<[Value], Error>

extension ViewController {
    func creatSignal7() {
        let (signal1, innerObserver1) = NSignal<Int>.pipe()
        let (signal2, innerObserver2) = NSignal<Int>.pipe()
        let (signal3, innerObserver3) = NSignal<Int>.pipe()
        
        Signal.combineLatest(signal1 ,signal2 ,signal3).observeValues { (tuple) in
            print("received value :\(tuple)")
        }
        
        innerObserver1.send(value: 1)
        innerObserver2.send(value: 2)
        innerObserver3.send(value: 3)
        
        // 每次发送都会刷新值
        innerObserver1.send(value: 10)
        innerObserver2.send(value: 11)
        innerObserver3.send(value: 12)
        
        
        innerObserver1.sendCompleted()
        innerObserver2.sendCompleted()
        innerObserver3.sendCompleted()
    }
}


//MARK: 8 zip: 新信号的Event是各个信号的最新的Event的进行拉链式组合.
//有人把这个叫压缩, 但我觉得拉链式组合更贴切一些. 拉链的左右齿必须对齐才能拉上, 这个函数也是一样的道理. 只有各个信号发送Event的次数相同(对齐)时, 新信号才会发送组合值. 同理, 如果有信号未发送那么什么也不会发生.


// 函数方法
// public static func zip<S: Sequence>(_ signals: S) -> Signal<[Value], Error>

extension ViewController {
    func creatSignal8()  {
        let (signal1, innerObserver1) = NSignal<Int>.pipe()
        let (signal2, innerObserver2) = NSignal<Int>.pipe()
        let (signal3, innerObserver3) = NSignal<Int>.pipe()
        
        Signal.zip(signal1 ,signal2 ,signal3).observeValues { (tuple) in
            print("received value: \(tuple)")
        }
        innerObserver1.send(value: 1)
        innerObserver2.send(value: 2)
        innerObserver3.send(value: 3)
        
        innerObserver1.send(value: 11)
        innerObserver2.send(value: 22)
        innerObserver3.send(value: 33)
        
        // 发送的次数不相同，不执行
        innerObserver1.send(value: 111)
        innerObserver2.send(value: 222)
        
        innerObserver1.sendCompleted()
        innerObserver2.sendCompleted()
        innerObserver3.sendCompleted()
    }
    //   输出   received value: (1, 2, 3)
    //         received value: (11, 22, 33)
}

// MARK:  1.4  SignalProducer  -- SignalProducer是ReactiveSwift中冷信号的实现, 是第二种发送事件的途径.
//上文说到热信号是活动着的事件发生器, 相对应的, 冷信号则是休眠中的事件发生器. 也就是说冷信号需要一个唤醒操作, 然后才能发送事件, 而这个唤醒操作就是订阅它. 因为订阅后才发送事件, 显然, 冷信号不存在时机早晚的问题.

extension ViewController {
    
    func creatProducer() {
        //1. 通过SignalProducer.init(startHandler: (Observer, Lifetime) -> Void)创建SignalProducer
        let produce = SignalProducer<Int , NoError>.init { (innerObserver, lifetime) in
            lifetime.observeEnded({
                print("信号无效了，你可以在这里进行一些清理工作")
            })
            // 向外界发送事件
            innerObserver.send(value: 1)
            innerObserver.send(value: 2)
            innerObserver.sendCompleted()
        }
        //3. 创建一个观察者封装事件处理逻辑
        let outerObserver = Signal<Int , NoError>.Observer { (value) in
            print("did received value: \(value)")
        }
        //4. 添加观察者到SignalProducer
        produce.start(outerObserver)
        //输出
//        did received value: VALUE 1
//        did received value: VALUE 2
//        did received value: COMPLETED
//        信号无效了，你可以在这里进行一些清理工作
        typealias Producer<T> = ReactiveSwift.SignalProducer<T, NoError>
        let producer1 = Producer<Int> { (innerObserver1, _) in
            //没什么想清理的
            
            innerObserver1.send(value: 1)
            innerObserver1.send(value: 2)
            innerObserver1.sendCompleted()
        }
        producer1.startWithValues { (value) in
            print("did received value: \(value)")
        }
        //输出      did received value: 1
        //         did received value: 2
//        producer1.startWithFailed(action: )
//        producer1.startWithResult(action: )
//        producer1.startWithXXX...各种便利函数
        
//        但事实上这里会发生两次网络请求, 但这不是一个bug, 这是一个feature.
//        SignalProducer的一个特性是, 每次被订阅就会执行一次初始化时保存的闭包. 所以如果你有类似一次执行, 多处订阅的需求, 你应该选择Signal而不是SignalProducer. 所以, 符合需求的代码可能是这样:
//
        func fetchData(completionHandler: (Int, Error?) -> ()) {
            print("发起网络请求")
            completionHandler(1, nil)
        }
        
        let producer = Producer<Int> { (innerObserver, _) in
            fetchData(completionHandler: { (data, error) in
                innerObserver.send(value: data)
                innerObserver.sendCompleted()
            })
        }
        producer.startWithValues { (value) in
            print("did received value: \(value)")
        }
        producer.startWithValues { (value) in
            print("did received value: \(value)")
        }
        
//        输出: 发起网络请求
//        did received value: 1
//        发起网络请求
//        did received value: 1
    }
}


// MARK: 1.5 Property/MutableProperty
//ReactiveSwift发送事件的第三种途径是Property/MutableProperty. 从冷热信号的定义上来看, Property的行为应该属于热信号, 但和上文的Signal不同, Property/MutableProperty只提供一种状态的事件: Value.(虽然它有Completed状态),我们就暂且认为Property/MutableProperty代表那些不知道何时结束的现场直播吧.照例,


// MARK: 1 示例Property
//Property.value不可设置,

extension ViewController {
    //Property/MutableProperty内部有一个Producer一个Signal, 设置value即是在向这两个信号发送Value事件即可.
    func creayProperty() {
        let constant  =  Property.init(value: 1)
        // constant.value = 2  初始化的value不可变
        print("initial value is: \(constant.value)")
        
        constant.producer.startWithValues { (value) in
            print("producer received :\(value)")
        }
        
        constant.signal.observeValues { (value) in
            print("signal received :\(value)")
        }
        // 输出   initial value is: 1
        //       producer received :1
    }
}

// MARK: 2 示例Property
//MutableProperty.value可设置
extension ViewController {
    //Property/MutableProperty内部有一个Producer一个Signal, 设置value即是在向这两个信号发送Value事件即可.
    func creatMutableProperty() {
        let mutableProperty = MutableProperty(1)
        print("initial value is :\(mutableProperty.value)")
        
        mutableProperty.producer.startWithValues { (value) in // 冷信号可以收到初始值以及后面的值
            print("producer received :\(value)")
        }
        
        mutableProperty.signal.observeValues { (value) in // 热信号只能收到后续的变化值value
            print("signal received :\(value)")
        }
        
        mutableProperty.value = 2  // 设置value就是在发送事件
        mutableProperty.value = 3
        
//        输出
//        initial value is :1
//        producer received :1
//        producer received :2
//        signal received :2
//        producer received :3
//        signal received :3
    }
}

extension  ViewController {
    func addtextFiled() {
        let errorlable:UILabel
        let sendButton:UIButton
        let phoneNumberTextFiled:UITextField
        
        errorlable = UILabel.init(frame: CGRect(x: 30, y: 100, width: 100, height: 50))
        errorlable.backgroundColor = .yellow
        sendButton = UIButton.init(frame: CGRect(x: 30, y: 200, width: 100, height: 50))
        
        phoneNumberTextFiled = UITextField(frame: CGRect(x: 30, y: 300, width: 100, height: 50))
        phoneNumberTextFiled.backgroundColor = .blue
        
        view.addSubview(errorlable)
        view.addSubview(sendButton)
        view.addSubview(phoneNumberTextFiled)
        
        let errortext = MutableProperty("")
        let validPhoneNumber = MutableProperty("")
        
        errorlable.reactive.text <~ errortext
        sendButton.reactive.isEnabled <~ errortext.map({ $0.count == 0})
        sendButton.reactive.backgroundColor <~ errortext.map({ $0.count == 0 ? UIColor.red : UIColor.gray })
        phoneNumberTextFiled.reactive.text <~ validPhoneNumber //
        
        validPhoneNumber <~ phoneNumberTextFiled.reactive.continuousTextValues.map({ (text) in
            let phoneNumer = text  //1. 最多输入11个数字, 多余部分截掉
            let isValidPhoneNum = NSPredicate(format: "SELF MATCHES %@", "正则表达式...").evaluate(with: phoneNumer) //2. 检查手机格式是否正确
            errortext.value = isValidPhoneNum ? "手机号格式不正确" : "" //2. 格式不正确显示错误信息
            return phoneNumer //3. 返回截取后的有效输入
        })
    }
}

// MARK: 1.6 Action/CocoaAction ：Action是最后一种发送事件的途径, 不过和其他途径不同, 它并不直接发送事件, 而是生产信号, 由生产的信号来发送事件. 最重要的是, Action是唯一一种可以接受订阅者输入的途径.

// 代码示例
// public final class Action<Input, Output, Error: Swift.Error>
//public convenience init(execute: @escaping (Input) -> SignalProducer<Output, Error>)

//typealias APIAction<O> = ReactiveSwift.Action<[String: String]?, O, APIError>
extension ViewController {
    
}


