import SwiftUI
import CorePresentation
import CoreDomain
import CoreData

// MARK: - HomeFeed View
public struct HomeFeedView: View {
    @StateObject private var viewModel = HomeFeedViewModel()
    @State private var showUserMenu = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    EmptyStateView(
                        title: "No Posts Yet",
                        message: "Be the first to share something amazing!",
                        systemImage: "doc.text.image",
                        actionTitle: viewModel.isLoggedIn ? "Create Post" : "Login to Post",
                        action: {
                            if viewModel.isLoggedIn {
                                viewModel.showCreatePostView()
                            } else {
                                // Navigate to login
                            }
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Search Bar
                            SearchBar(text: $viewModel.searchText)
                                .padding(.horizontal)
                            
                            // Posts List
                            ForEach(viewModel.posts) { post in
                                PostCardView(post: post) {
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                } onTap: {
                                    viewModel.selectPost(post)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Load More Indicator
                            if viewModel.hasMorePosts && !viewModel.searchText.isEmpty == false {
                                ProgressView()
                                    .padding()
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isLoggedIn {
                        UserAvatarButton(user: viewModel.currentUser) {
                            showUserMenu = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showCreatePostView() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .task {
                await viewModel.loadInitialPosts()
            }
            .overlay {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $viewModel.showCreatePost) {
                CreatePostView()
            }
            .sheet(item: $viewModel.selectedPost) { post in
                PostDetailView(post: post)
            }
            .sheet(isPresented: $showUserMenu) {
                UserMenuView()
            }
        }
    }
}

// MARK: - Post Card View
struct PostCardView: View {
    let post: Post
    let onLike: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author Info
            HStack {
                AsyncImage(url: URL(string: post.author.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Post Content
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(post.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            .onTapGesture(perform: onTap)
            
            // Post Image
            if let imageURL = post.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(maxHeight: 200)
                .clipped()
                .cornerRadius(8)
            }
            
            // Actions
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .secondary)
                        Text("\(post.likesCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.secondary)
                        Text("0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .foregroundColor(.secondary)
                }
            }
            .font(.callout)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Create Post View
struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                        TextField("Enter post title", text: $viewModel.title)
                            .customTextFieldStyle()
                    }
                    
                    // Content Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Content")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.remainingCharacters) characters")
                                .font(.caption)
                                .foregroundColor(viewModel.remainingCharacters < 100 ? .red : .secondary)
                        }
                        
                        TextEditor(text: $viewModel.content)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    // Image Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Image (Optional)")
                            .font(.headline)
                        
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 200)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(alignment: .topTrailing) {
                                    Button(action: { viewModel.selectedImage = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(8)
                                }
                        } else {
                            Button(action: { showImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Add Image")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await viewModel.createPost()
                            if viewModel.postCreated {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

// MARK: - Post Detail View
struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    
    init(post: Post) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(post: post))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Author Info
                    HStack {
                        AsyncImage(url: URL(string: viewModel.post.author.avatarURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.post.author.name)
                                .font(.headline)
                            
                            Text(viewModel.post.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if viewModel.isOwner {
                            Menu {
                                Button(role: .destructive, action: { showDeleteAlert = true }) {
                                    Label("Delete Post", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Post Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.post.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(viewModel.post.content)
                            .font(.body)
                    }
                    .padding(.horizontal)
                    
                    // Post Image
                    if let imageURL = viewModel.post.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.2))
                                .overlay {
                                    ProgressView()
                                }
                        }
                        .frame(maxHeight: 400)
                    }
                    
                    // Actions
                    HStack(spacing: 32) {
                        Button(action: {
                            Task {
                                await viewModel.toggleLike()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.post.isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(viewModel.post.isLiked ? .red : .primary)
                                Text("\(viewModel.post.likesCount)")
                            }
                        }
                        
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left")
                                Text("0")
                            }
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "paperplane")
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "bookmark")
                        }
                    }
                    .font(.title3)
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Related Posts
                    if !viewModel.relatedPosts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Posts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.relatedPosts) { post in
                                        RelatedPostCard(post: post)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadRelatedPosts()
            }
            .alert("Delete Post", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deletePost()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Helper Views
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search posts...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct UserAvatarButton: View {
    let user: User?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AsyncImage(url: URL(string: user?.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
        }
    }
}

struct UserMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Profile", systemImage: "person.circle")
                    Label("Settings", systemImage: "gear")
                    Label("Saved Posts", systemImage: "bookmark")
                }
                
                Section {
                    Button(role: .destructive, action: {}) {
                        Label("Logout", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RelatedPostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageURL = post.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.2))
                }
                .frame(width: 150, height: 100)
                .clipped()
                .cornerRadius(8)
            }
            
            Text(post.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            Text(post.author.name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
    }
}

// MARK: - Preview
struct HomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        HomeFeedView()
    }
}
