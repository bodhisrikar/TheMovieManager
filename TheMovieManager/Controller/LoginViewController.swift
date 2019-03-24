//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        configureLoggingIn(true)
        TMDBClient.getRequestToken(completionHandler: tokenResponseHandler(success:error:))
    }
    
    @IBAction func loginViaWebsiteTapped() {
        configureLoggingIn(true)
        TMDBClient.getRequestToken(completionHandler: webTokenResponseHandler(success:error:))
    }
    
    func handleSessionResponse(success: Bool, error: Error?) {
        if success {
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        } else {
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    private func tokenResponseHandler(success: Bool, error: Error?) {
        configureLoggingIn(false)
        if success {
            TMDBClient.validateLogin(username: self.emailTextField.text ?? "", password: self.passwordTextField.text ?? "", completionHandler: self.handleTokenResponse(success:error:))
        } else {
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    private func handleTokenResponse(success: Bool, error: Error?) {
        if success {
            TMDBClient.createSession(completionHandler: handleSessionResponse(success:error:))
        } else {
            showLoginFailure(message: error?.localizedDescription ?? "")
        }
    }
    
    private func webTokenResponseHandler(success: Bool, error: Error?) {
        if success {
            UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
        }
    }
    
    private func configureLoggingIn(_ loggingIn: Bool) {
        if loggingIn {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        loginViaWebsiteButton.isEnabled = !loggingIn
    }
    
    private func showLoginFailure(message: String) {
        let alertVC = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
    
}