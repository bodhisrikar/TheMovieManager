//
//  MovieDetailViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    var movie: Movie!
    
    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }
    
    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = movie.title
        if let posterPath = movie.posterPath {
            TMDBClient.downloadPosterImage(posterPath: posterPath) { (data, error) in
                if let data = data {
                    let image = UIImage(data: data)
                    self.imageView.image = image
                }
            }
        }
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        
    }
    
    @IBAction func watchlistButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.modifyMoviesWatchlist(movieId: movie.id, isWatchlist: !isWatchlist, completionHandler: handleModifyWatchlistResponse(success:error:))
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.modifyMoviesFavorites(movieId: movie.id, isFavorite: !isFavorite, completionHandler: handleModifyFavoriteResponse(success:error:))
    }
    
    func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }
    
    private func handleModifyWatchlistResponse(success: Bool, error: Error?) {
        if success {
            if isWatchlist {
                MovieModel.watchlist = MovieModel.watchlist.filter({$0 != self.movie})
            } else {
                MovieModel.watchlist.append(movie)
            }
        }
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
    }
    
    private func handleModifyFavoriteResponse(success: Bool, error: Error?) {
        if success {
            if isFavorite {
                MovieModel.favorites = MovieModel.favorites.filter({$0 != self.movie})
            } else {
                MovieModel.favorites.append(movie)
            }
        }
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
    }
    
    
}
