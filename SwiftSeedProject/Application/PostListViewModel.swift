//
//  PostListViewModel.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 02/05/2020.
//  Copyright © 2020 Making Sense. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

class PostListViewModel: ViewModelBase {
    
    private let postService: PostService!
    private let subredditService: SubredditService!

    let subreddit = "CryptoCurrencies" // We could support multiple subreddits but let's hardcode this one for this test
    let pageSize = 10 // We could make this value configurable but let's hardcode this one for this test
    let posts = BehaviorRelay<[SectionModel<String, PostViewModel>]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    
    var shouldLoad: Bool = false
    var lastItem: String? = nil

    init(postService: PostService, subredditService: SubredditService) {
        self.postService = postService
        self.subredditService = subredditService
        let subreddit = subredditService.getSubreddit(title: self.subreddit)
        self.lastItem = subreddit?.after
        let cachedPosts = postService.getAll(conditions: nil, orderBy: ["timestamp"])
        self.shouldLoad = cachedPosts.count == 0
        posts.accept([SectionModel(model: "", items: cachedPosts.map { PostViewModel(post: $0) })])
    }
        
    public func selectPost(_ postViewModel: PostViewModel) {
        postViewModel.wasViewed.accept(true)
        let postId = postViewModel.identifier.value
        let post = postService.getEntityBy(id: postId)!
        post.wasViewed = true
        postService.persistence.save(object: post)
        postService.currentPostId = postId
        navigationDelegate?.navigate(SegueIdentifier.PostDetails)
    }
    
    public func getTopPosts(forceLoad: Bool = false) {
        if !isLoading.value && (shouldLoad || forceLoad) {
            isLoading.accept(true)
            postService.getTopPostsFromServer(from: subreddit, after: lastItem, limit: pageSize, onSuccess: { [weak self] posts in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.posts.accept([SectionModel(model: "", items: weakSelf.postService.getAll(conditions: nil, orderBy: ["timestamp"]).map { PostViewModel(post: $0) })])
                weakSelf.lastItem = posts.1.after
                weakSelf.isLoading.accept(false)
            })
        }
    }
}
