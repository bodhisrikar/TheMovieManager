//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = AppConstants.API_KEY
    
    private struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        static let requestToken = "/authentication/token/new"
        static let loginValidation = "/authentication/token/validate_with_login"
        static let createSession = "/authentication/session/new"
        static let deleteSession = "/authentication/session"
        
        case getRequestToken
        case createSessionId
        case validateLogin
        case webAuth
        case search(String)
        case getWatchlist
        case getFavorites
        case modifyWatchlist
        case modifyFavorites
        case posterImage(String)
        case logout
        
        var stringValue: String {
            switch self {
            case .getWatchlist:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)" +
                "&sort_by=created_at.desc"
            case .getRequestToken:
                return Endpoints.base + Endpoints.requestToken + Endpoints.apiKeyParam
            case .validateLogin:
                return Endpoints.base + Endpoints.loginValidation + Endpoints.apiKeyParam
            case .createSessionId:
                return Endpoints.base + Endpoints.createSession + Endpoints.apiKeyParam
            case .webAuth:
                return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
            case .logout:
                return Endpoints.base + Endpoints.deleteSession + Endpoints.apiKeyParam
            case .getFavorites:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .search(let query):
                return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam +
                "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .modifyWatchlist:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .modifyFavorites:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .posterImage(let posterPath):
                return "https://image.tmdb.org/t/p/w500/\(posterPath)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func getRequestToken(completionHandler: @escaping (Bool, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getRequestToken.url, responseType: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    class func getFavorites(completionHandler: @escaping([Movie], Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getFavorites.url, responseType: MovieResults.self) { (response, error) in
            if let reponse = response {
                completionHandler(reponse.results, nil)
            } else {
                completionHandler([], error)
            }
        }
    }
    
    class func search(query: String, completionHandler: @escaping([Movie], Error?) -> Void) -> URLSessionTask {
        let task = taskForGETRequest(url: Endpoints.search(query).url, responseType: MovieResults.self) { (response, error) in
            if let response = response {
                completionHandler(response.results, nil)
            } else {
                completionHandler([], nil)
            }
        }
        return task
    }
    
    @discardableResult class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type,
                                                          completionHandler: @escaping(ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let tokenDecoder = try decoder.decode(responseType, from: data)
                DispatchQueue.main.async {
                    completionHandler(tokenDecoder, nil)
                }
            } catch {
                do {
                    let errorResponse = try JSONDecoder().decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(nil, errorResponse)
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
    class func validateLogin(username: String, password: String, completionHandler: @escaping(Bool, Error?) -> Void) {
        let loginData = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        
        taskForPOSTRequest(url: Endpoints.validateLogin.url, requestBody: loginData, responseType: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    class func createSession(completionHandler: @escaping(Bool, Error?) -> Void) {
        let sessionData = PostSession(requestToken: Auth.requestToken)
        
        taskForPOSTRequest(url: Endpoints.createSessionId.url, requestBody: sessionData, responseType: SessionResponse.self) { (response, error) in
            if let response = response {
                Auth.sessionId = response.sessionId
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType:Decodable>(url: URL, requestBody: RequestType,
                                                                                  responseType: ResponseType.Type,
                                                                                  completionHandler: @escaping(ResponseType?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(requestBody)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let sessionResponseData = try decoder.decode(responseType, from: data)
                DispatchQueue.main.async {
                    completionHandler(sessionResponseData, nil)
                }
            } catch {
                do {
                    let errorResponse = try JSONDecoder().decode(TMDBResponse.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(nil, errorResponse)
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                }
            }
            
        }
        task.resume()
    }
    
    class func deleteSession(completionHandler: @escaping (Bool, Error?) -> Void) {
        var deleteRequest = URLRequest(url: Endpoints.logout.url)
        deleteRequest.httpMethod = "DELETE"
        deleteRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let deleteBody = LogoutRequest(sessionId: Auth.sessionId)
        deleteRequest.httpBody = try! JSONEncoder().encode(deleteBody)
        
        let task = URLSession.shared.dataTask(with: deleteRequest) { (data, response, error) in
            guard let data = data else {
                completionHandler(false, error)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedLogoutData = try decoder.decode(LogoutResponse.self, from: data)
                Auth.requestToken = ""
                Auth.sessionId = ""
                completionHandler(decodedLogoutData.success, nil)
            } catch let error {
                completionHandler(false, error)
            }
        }
        task.resume()
    }
    
    class func modifyMoviesWatchlist(movieId: Int, isWatchlist: Bool, completionHandler: @escaping(Bool, Error?) -> Void) {
        let watchlistBody = MarkWatchlist(mediaType: "movie", mediaId: movieId, watchlist: isWatchlist)
        taskForPOSTRequest(url: Endpoints.modifyWatchlist.url, requestBody: watchlistBody, responseType: TMDBResponse.self) { (response, error) in
            if let response = response {
                completionHandler(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completionHandler(false, nil)
            }
        }
    }
    
    class func modifyMoviesFavorites(movieId: Int, isFavorite: Bool, completionHandler: @escaping(Bool, Error?) -> Void) {
        let favoritesBody = MarkFavorite(mediaType: "movie", mediaId: movieId, favorite: isFavorite)
        taskForPOSTRequest(url: Endpoints.modifyFavorites.url, requestBody: favoritesBody, responseType: TMDBResponse.self) { (response, error) in
            if let response = response {
                completionHandler(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
            } else {
                completionHandler(false, nil)
            }
        }
    }
    
    class func downloadPosterImage(posterPath: String, completionHandler: @escaping(Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.posterImage(posterPath).url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(data, nil)
            }
        }
        task.resume()
    }
    
}
