import SwiftUI
import Combine
import CoreDomain
import CoreData
import CorePresentation
import HomeFeedDomain
import HomeFeedData

// MARK: - HomeFeed ViewModel
public class HomeFeedViewModel: BaseViewModel {
    @Published public var posts: [Post] = []
    @Published public var searchText = ""
    @Published public var isRefreshing = false
    @Published public var hasMorePosts = true
    @Published public var selectedPost: Post?
    @Published public var showCreatePost = false
    
    private let fetchPostsUseCase: FetchPostsUseCaseProtocol
    private let likePostUseCase: LikePostUseCaseProtocol
    private let unlikePostUseCase: UnlikePostUseCaseProtocol
    private let searchPostsUseCase: SearchPostsUseCaseProtocol
    private let sessionManager: SessionManager
    
    private var currentPage = 1
    private let pageLimit = 20
    private var searchCancellable: AnyCancellable?
    
    public var isLoggedIn: Bool {
        sessionManager.isLoggedIn
    }
    
    public var currentUser: User? {
        sessionManager.currentUser
    }
    
    public init(
        fetchPostsUseCase: FetchPostsUseCaseProtocol? = nil,
        likePostUseCase: LikePostUseCaseProtocol? = nil,
        unlikePostUseCase: UnlikePostUseCaseProtocol? = nil,
        searchPostsUseCase: SearchPostsUseCaseProtocol? = nil,
        sessionManager: SessionManager = .shared
    ) {
        let repository = PostRepository()
        self.fetchPostsUseCase = fetchPostsUseCase ?? FetchPostsUseCase(repository: repository)
        self.likePostUseCase = likePostUseCase ?? LikePostUseCase(repository: repository)
        self.unlikePostUseCase = unlikePostUseCase ?? UnlikePostUseCase(repository: repository)
        self.searchPostsUseCase = searchPostsUseCase ?? SearchPostsUseCase(repository: repository)
        self.sessionManager = sessionManager
        super.init()
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Debounce search
        searchCancellable = $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.handleSearch(searchText)
                }
            }
        
        // Listen to session changes
        sessionManager.$isLoggedIn
            .sink { [weak self] _ in
                Task {
                    await self?.refresh()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    public func loadInitialPosts() async {
        guard posts.isEmpty else { return }
        
        startLoading()
        currentPage = 1
        
        do {
            let input = FetchPostsInput(page: currentPage, limit: pageLimit)
            let fetchedPosts = try await fetchPostsUseCase.execute(input)
            
            posts = fetchedPosts
            hasMorePosts = fetchedPosts.count == pageLimit
            stopLoading()
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    public func loadMorePosts() async {
        guard !isLoading && hasMorePosts && searchText.isEmpty else { return }
        
        currentPage += 1
        startLoading()
        
        do {
            let input = FetchPostsInput(page: currentPage, limit: pageLimit)
            let fetchedPosts = try await fetchPostsUseCase.execute(input)
            
            posts.append(contentsOf: fetchedPosts)
            hasMorePosts = fetchedPosts.count == pageLimit
            stopLoading()
        } catch {
            currentPage -= 1
            handleError(error)
        }
    }
    
    @MainActor
    public func refresh() async {
        isRefreshing = true
        currentPage = 1
        searchText = ""
        
        do {
            let input = FetchPostsInput(page: currentPage, limit: pageLimit)
            let fetchedPosts = try await fetchPostsUseCase.execute(input)
            
            posts = fetchedPosts
            hasMorePosts = fetchedPosts.count == pageLimit
            isRefreshing = false
        } catch {
            isRefreshing = false
            handleError(error)
        }
    }
    
    @MainActor
    public func toggleLike(for post: Post) async {
        guard isLoggedIn else {
            errorMessage = "Please login to like posts"
            showError = true
            return
        }
        
        do {
            let updatedPost: Post
            if post.isLiked {
                updatedPost = try await unlikePostUseCase.execute(post.id)
            } else {
                updatedPost = try await likePostUseCase.execute(post.id)
            }
            
            // Update the post in the list
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = updatedPost
            }
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    private func handleSearch(_ query: String) async {
        guard !query.isEmpty else {
            // If search is cleared, reload posts
            await loadInitialPosts()
            return
        }
        
        startLoading()
        
        do {
            let searchResults = try await searchPostsUseCase.execute(query)
            posts = searchResults
            hasMorePosts = false // Disable pagination for search results
            stopLoading()
        } catch {
            handleError(error)
        }
    }
    
    public func selectPost(_ post: Post) {
        selectedPost = post
    }
    
    public func showCreatePostView() {
        guard isLoggedIn else {
            errorMessage = "Please login to create posts"
            showError = true
            return
        }
        showCreatePost = true
    }
}

// MARK: - Create Post ViewModel
public class CreatePostViewModel: BaseViewModel {
    @Published public var title = ""
    @Published public var content = ""
    @Published public var selectedImage: UIImage?
    @Published public var postCreated = false
    
    private let createPostUseCase: CreatePostUseCaseProtocol
    
    public var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var characterCount: Int {
        content.count
    }
    
    public var remainingCharacters: Int {
        5000 - characterCount
    }
    
    public init(createPostUseCase: CreatePostUseCaseProtocol? = nil) {
        let repository = PostRepository()
        self.createPostUseCase = createPostUseCase ?? CreatePostUseCase(repository: repository)
        super.init()
    }
    
    @MainActor
    public func createPost() async {
        startLoading()
        
        do {
            let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
            let input = CreatePostInput(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                imageData: imageData
            )
            
            _ = try await createPostUseCase.execute(input)
            
            stopLoading()
            postCreated = true
        } catch {
            handleError(error)
        }
    }
    
    public func clearForm() {
        title = ""
        content = ""
        selectedImage = nil
    }
}

// MARK: - Post Detail ViewModel
public class PostDetailViewModel: BaseViewModel {
    @Published public var post: Post
    @Published public var relatedPosts: [Post] = []
    
    private let likePostUseCase: LikePostUseCaseProtocol
    private let unlikePostUseCase: UnlikePostUseCaseProtocol
    private let deletePostUseCase: DeletePostUseCaseProtocol
    private let fetchPostsUseCase: FetchPostsUseCaseProtocol
    private let sessionManager: SessionManager
    
    public var isOwner: Bool {
        sessionManager.currentUser?.id == post.author.id
    }
    
    public var isLoggedIn: Bool {
        sessionManager.isLoggedIn
    }
    
    public init(
        post: Post,
        likePostUseCase: LikePostUseCaseProtocol? = nil,
        unlikePostUseCase: UnlikePostUseCaseProtocol? = nil,
        deletePostUseCase: DeletePostUseCaseProtocol? = nil,
        fetchPostsUseCase: FetchPostsUseCaseProtocol? = nil,
        sessionManager: SessionManager = .shared
    ) {
        self.post = post
        let repository = PostRepository()
        self.likePostUseCase = likePostUseCase ?? LikePostUseCase(repository: repository)
        self.unlikePostUseCase = unlikePostUseCase ?? UnlikePostUseCase(repository: repository)
        self.deletePostUseCase = deletePostUseCase ?? DeletePostUseCase(repository: repository)
        self.fetchPostsUseCase = fetchPostsUseCase ?? FetchPostsUseCase(repository: repository)
        self.sessionManager = sessionManager
        super.init()
    }
    
    @MainActor
    public func toggleLike() async {
        guard isLoggedIn else {
            errorMessage = "Please login to like posts"
            showError = true
            return
        }
        
        do {
            if post.isLiked {
                post = try await unlikePostUseCase.execute(post.id)
            } else {
                post = try await likePostUseCase.execute(post.id)
            }
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    public func deletePost() async {
        guard isOwner else {
            errorMessage = "You can only delete your own posts"
            showError = true
            return
        }
        
        startLoading()
        
        do {
            try await deletePostUseCase.execute(post.id)
            stopLoading()
            // Post deleted successfully - view should dismiss
        } catch {
            handleError(error)
        }
    }
    
    @MainActor
    public func loadRelatedPosts() async {
        do {
            let input = FetchPostsInput(page: 1, limit: 5)
            let posts = try await fetchPostsUseCase.execute(input)
            relatedPosts = posts.filter { $0.id != post.id }
        } catch {
            // Silently fail for related posts
            print("Failed to load related posts: \(error)")
        }
    }
}
