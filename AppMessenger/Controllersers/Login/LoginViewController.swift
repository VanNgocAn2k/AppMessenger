//
//  LoginViewController.swift
//  AppMessenger
//
//  Created by Van Ngoc An  on 17/11/2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import FirebaseCore
import GoogleSignIn

class LoginViewController: UIViewController {

    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address,,,"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password,,,"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    private let loginButtom: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    // Nút login của Facebook
    private let facebookLoginButton: FBLoginButton = {
      let fbLogin = FBLoginButton()
        // Cấp quyền đọc cho nút login
        fbLogin.permissions = ["email", "public_profile"]
        return fbLogin
    }()
    
    // Nut log in google
    private let googleLogInButton = GIDSignInButton()
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Log in"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        loginButtom.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleLogInButton.addTarget(self, action: #selector(googleButtonTapped), for: .touchUpInside)
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true)
         })
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        // them View
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButtom)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogInButton)
    }
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        loginButtom.frame = CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
        facebookLoginButton.frame = CGRect(x: 30, y: loginButtom.bottom+10, width: scrollView.width-60, height: 52)
        
        facebookLoginButton.frame.origin.y = loginButtom.bottom+20
        
        googleLogInButton.frame = CGRect(x: 30, y: facebookLoginButton.bottom+10, width: scrollView.width-60, height: 52)
        
    }
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                
                return
            }
            guard let result = authResult, error == nil else {
                print("Failed: \(email)")
                return
            }
            let user = result.user
            print("Login User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true)
        })
        
    }
    
    @objc private func googleButtonTapped() {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in

            if error != nil {
            // ...
            return
          }
//            guard let user = user else {
//                return
//            }
//            print("Failed ti sign in Google : \(user)")
            guard let email = user?.profile?.email,
                 let firstName = user?.profile?.givenName,
                 let lastName = user?.profile?.familyName else {
               return
           }
            DatabaseManager.shared.userExist(with: email, completion: { exists in
                if !exists {
                    // insert to database
                    DatabaseManager.shared.insertUser(with: AppMessengerUser(firstName: firstName, lastName: lastName, emailAddress: email))
                    
                }
            })

          guard
            let authentication = user?.authentication,
            let idToken = authentication.idToken
          else {
              print("Missing auth object off google user")
            return
          }

          let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: authentication.accessToken)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
                guard authResult != nil, error == nil else {
                    print("Failed to log in with google credential")
                    return
                }
                print("Successfully signed in with Google credential")
            })
//            guard let strongSelf = self else {
//                return
//            }
//            print("Successfully logged user in")
//            strongSelf.navigationController?.dismiss(animated: true)
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
    }
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Rất tiếc", message: "Vui lòng nhập đầy đủ thông tin để đăng nhập", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Bỏ qua", style: .cancel))
        present(alert, animated: true)
    }
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}
extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // để cho có thôi
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        // Lấy mã truy cập accessToken
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, name"], tokenString: token, version: nil, httpMethod: .get)

        facebookRequest.start(completion: { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
           
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String else {
                print("Failed to get email and name from facebook result")
                return
            }

            let nameComponents = userName.components(separatedBy: " ")
//            guard nameComponents.count == 2 else {
//                return
//            }

            let firstName = nameComponents[0]
            let lastName = nameComponents[1]

            DatabaseManager.shared.userExist(with: email, completion: { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: AppMessengerUser(firstName: firstName, lastName: lastName, emailAddress: email))
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed- \(error)")
                        
                    }
                    return
                }
                print("Successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true)
            })
        })
    
    }
}
