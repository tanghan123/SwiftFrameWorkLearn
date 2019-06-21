//
//  /Users/chaomeng/Documents/Swift框架学习使用/RactiveCocoaMethod/RactiveCocoaMethod/ViewController.swiftViewController.swift
//  RactiveCocoaMethod
//
//  Created by chaomeng on 2019/6/3.
//  Copyright © 2019 Jacob. All rights reserved.
//

// 参考文章 https://github.com/EvilNOP/ReactivePlayground-Final
// 简书 https://www.jianshu.com/p/3a56d10e99a7

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result

class ViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var pasdword: UITextField!
    
    @IBOutlet weak var signFailureLable: UILabel!
    
    @IBOutlet weak var signIn: UIButton!
    
    private let signInService : DummySignInService = DummySignInService()
    
     var tableView:UITableView!
    
    var userTextFild : UITextField!
    
    var isValidusername : Bool  {
       return self.username.text!.count > 3
    }
    
    var isValidpsd : Bool  {
        return self.pasdword.text!.count > 3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
       creatAction2()
    }
}

// MARK: 1. 创建信号并且发送信号
extension ViewController {
    func creatSignalDemp1()  {
        let signalDemo1 = SignalDemo1.init()
        signalDemo1.creatSignal2()
    }
}

// MARK: 2

extension ViewController {
    fileprivate func configureView() {
        signFailureLable.isHidden = true
        
//        userTextFild = UITextField.init(frame: CGRect(x: 30, y: 50, width: 300, height: 50))
//        userTextFild.placeholder = "输入"
//        userTextFild.borderStyle = UITextField.BorderStyle.line
//        view.addSubview(userTextFild)

        // 监听输入的字符
        //  userTextFild.reactive 将userTextFild变成可响应 ，continuousTextValues就是text值的信号 observeValues 可以观察continuousTextValues信号传来的Value事件
        
//        userTextFild.reactive.continuousTextValues.observeValues { text in
//            print(text)
//        }
        
//        ReactiveCocoa信号会发送一系列的事件给订阅者（观察者）。ReactiveCocoa有以下事件：
//
//        Value事件：Value事件提供了新值
//        Failed事件：Failed事件表明在信号完成之前发生了错误
//        Completed事件：Completed事件信号完成了，之后不会再有新的值发送
//        Interrupted事件：Interrupted事件表明由于被取消，信号被终止了
        
        
        //注意到我们新添加的map函数，给map函数提供一个closure，它就能够转换事件的数据对于每一次map接收到的Value事件，它就会运行closure，以closure的返回值作为Value事件发送出去。上面的代码中，我们的text的值映射成text的字符数
        username.reactive.continuousTextValues.map { text  in
            print(text.count)
            return text.count
            }.filter { count -> Bool in
                return count > 3
            }.observeValues { count in
                print(count)
        }
        
        pasdword.reactive.continuousTextValues.map { text in
            return text.count
            }.filter { count -> Bool in
                return count > 3
            }.observeValues { count in
                print(count)
        }
        
//
        // MARK: 创建合法状态的信号
        // 创建信号，使用map函数将text的值映射成bool
        let validusernameSignal = username.reactive.continuousTextValues.map { text in
            return self.isValidusername
        }

        
        let validPsdSignal = pasdword.reactive.continuousTextValues.map { text in
            return self.isValidpsd
        }
        
        // 使用map将Bool映射成UiColor ，然后观察Value的值 ，根据Value事件传来的颜色来改变userTextFiled的背景色
        validusernameSignal.map { isValidusername in
            return isValidusername ? UIColor.clear : UIColor.yellow
            }.observeValues { backGroundColor in
                self.username.backgroundColor = backGroundColor
        }
        
        validPsdSignal.map { isValidusername in
            return isValidusername ? UIColor.clear : UIColor.yellow
            }.observeValues { backGroundColor in
                self.pasdword.backgroundColor = backGroundColor
        }
        
        //Signal（Signal是ReactiveSwift的基本类型，所以我们要import ReactiveSwift）的Signal.combineLatest方法将validUsernameSignal和validPasswordSignal两个信号结合在一起，
  
        
//        let signUpActiveSignal = Signal.combineLatest(validusernameSignal, validPsdSignal)
        
//        signUpActiveSignal.map { (isusername , ispsd) in
//            return isusername && ispsd
//            }.observeValues { signupAction in
//               self.signIn.isEnabled = signupAction
//        }
      
        
    //一行搞定signInButton的可用性。<~操作符的左边应为遵循了BindingTarget的协议的类型，而右边是信号（Signal）的类型。
    //    signIn.reactive.isEnabled <~ Signal.combineLatest(validusernameSignal, validPsdSignal).map({ $0 && $1 })
        
  //可分开的（Splitting）：信号可用拥有多个订阅者（观察者），来作为后续步骤的信号源。注意到validUsernameSignal和validPasswordSignal是两个用来验证username text field和password text field分开的合法的信号，这两个信号有着不同的目的。
        
      // 可结合的（Combining）：多个信号可以结合在一起来创建一个新的信号。更值得兴奋的是，你可以结合任意类型的信号来创建新的信号。
        
        //touchUpInside事件
        let signInSignal = signIn.reactive.controlEvents(.touchUpInside)
        signInSignal.observeValues {_ in
            print("button Clicked")
        }
        
        //当observer发送一个Value事件，我们通过观察信号来看到它的值。
        signIn.reactive.controlEvents(.touchUpInside).map {
            self.creatSignInSignal()
            }.observeValues {
                //信号中的信号，也就是说一个外部的信号包含了内部的信号 ,还是信号的描述
                print("sign in result :\(String(describing: $0))")
        }
        
        //通过使用flatMap函数，结合flatten策略（.latest），我们保证了我们观察的值是内部的信号的值（也就是最新的值）。
        signIn.reactive.controlEvents(.touchUpInside).flatMap(.latest) {_ in
            self.creatSignInSignal()
            }.observeValues { success in
                print("Sign in result: \(success)")
        }
        
        //们使用了flatMap,并且flatten策略为.latest，保证我们接收到的信号是最新的。用户点击后应该禁用item，或者登录失败，需要以下处理方法
//        signIn.reactive.controlEvents(.touchUpInside).flatMap(.latest) { _ in
//            self.creatSignInSignal()
//            }.observeValues { succens in
//                if succens {
//
//                }
//        }
        
        
//        let signalProducer = SignalProducer<Void ,NoError>.init(signIn.reactive.controlEvents(.touchUpInside)).on(
//            starting : nil , started : nil ,
//            event: { _ in
//                self.signIn.isEnabled = false
//                self.signFailureLable.isHidden = true
//            },
//            value: nil ,failed : nil ,completed: nil, interrupted: nil, terminated: nil , disposed: nil)
//
//        signalProducer.flatMap(.latest, transform: {
//            self.createSignInSignalProducer()
//        }).startWithValues {
//            success in
//
//            self.signInButton.isEnabled = true
//            self.signInFailureTextLabel.isHidden = success
//
//            if success {
//                self.performSegue(withIdentifier: "signInSuccess", sender: self)
//            }
//        }
//
//        signalProducer.start()
        
        //
        let signUpActiveSignal = Signal.combineLatest(validusernameSignal, validPsdSignal).map { $0 && $1}
        
        // Property 接收一个初始的值 ， 设置为false ， 之后这个property会随着signUpActiveSignal里面的值变化而变化。
        let signalButtonEnabledPropertu = Property.init(initial: false, then: signUpActiveSignal)
        
        // Action是一个泛型为Action<Input, Output, SwiftError>，Action就是动作的意思，比如当用户点击了signInButton后应该发生的动作。Action可以有输入和输出，也可以没有。
        
        //enabledIf这个参数是一个信号，这个信号用来控制signInButton的启用/禁用。后面一个参数是一个closure，它的原型为(Input) -> SignalProducer<Output, Error>)，这个closure的Input来自于我们的username text field和password text field的值。
        let action = Action<(String ,String) ,Bool , NoError>.init(enabledIf: signalButtonEnabledPropertu) { (username , password) in
            return self.createSignalproducer(withUserName: username, andPassword: password)
        }
        
        //通过action.values.observeValues我们可以观察到Value事件，也就是我们登录成功与否的值。
        action.values.observeValues { success in
            self.signFailureLable.isHidden = success
            if success {
                print("success")
            }
        }
        
        //最后，signInButton.reactive.pressed是一个CocoaAction，当用户点击了signInButton就会触发这个CocoaAction，CocoaAction同时会帮你控制signInButton的启用/禁用状态。
        signIn.reactive.pressed = CocoaAction<UIButton>.init(action, { _ in
            (self.username.text! ,self.pasdword.text!)
        })
        // 实例化  CocoaAction<UIButton>(action: Action<Input, Output, Error>, inputTransform: (UIButton) -> Input)
        //CocoaAction传递给Action的Input才是动态的，也就是username text field和password text field当前的值。
        
    }
}

// MARK: 创建自定义信号
extension ViewController {
    
    // 使用Signal的pipe方法创建信号，返回一个元组Signal<Bool , NoError>
   private func creatSignInSignal() -> Signal<Bool , NoError> {
        let (signInSignal , observer) = Signal<Bool , NoError>.pipe()
        self.signInService.signIn(withUserName: self.username.text!, andPassword: self.pasdword.text!) { success in
            // 使用observer发送事件控制pipe方法返回的信号
            observer.send(value: success)
            // 信号会保持有效直到observer发送完成（completed）事件
            observer.sendCompleted()
        }
        return signInSignal
    }
    
  //为了演示信号中的信号和如何处理信号中的信号，我们添加了一个名字为createSignInSignal的方法。对于添加副作用，我们引入一个新的类SignalProducer。把createSignInSignal方法替换为
    private func createSignalproducer( withUserName username:String , andPassword password: String) -> SignalProducer<Bool ,NoError> {
        let (signInSignal , observer) = Signal<Bool , NoError>.pipe()
        
        let signInSignalProducer = SignalProducer<Bool , NoError>.init(signInSignal)
        self.signInService.signIn(withUserName: username, andPassword: password) { success  in
            observer.send(value: success)
            observer.sendCompleted()
        }
        
        return signInSignalProducer
    }
    
}


class DummySignInService {
    //
    func signIn(withUserName username:String , andPassword password: String, completion:@escaping(Bool) -> Void)  {
        
        let delay = 5.0
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            let success  =  (username == "user") && (password == "password")
            completion(success)
        }
        
    }
}
