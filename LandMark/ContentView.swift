import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]

    var body: some View {
        NavigationSplitView {
            ItemListView(items: items, onDelete: deleteItems)
                .navigationTitle("Items")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Add Item", systemImage: "plus", action: addItem)
                    }

                    #if os(iOS)
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    #endif
                }
        } detail: {
            ItemDetailView()
        }
    }

    private func addItem() {
        withAnimation(.easeInOut) {
            let newItem = Item(title: "Item \(items.count + 1)")
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation(.easeInOut) {
            offsets.forEach { index in
                modelContext.delete(items[index])
            }
        }
    }
}

// MARK: - Item List View
struct ItemListView: View {
    let items: [Item]
    let onDelete: (IndexSet) -> Void

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "tray",
                    description: Text("Add your first item to get started")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(items) { item in
                    ItemRowView(item: item)
                }
                .onDelete(perform: onDelete)
            }
        }
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        #endif
    }
}

// MARK: - Item Row View
struct ItemRowView: View {
    let item: Item

    var body: some View {
        NavigationLink(value: item) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)

                if let content = item.content, !content.isEmpty {
                    Text(content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(item.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Item Detail View
struct ItemDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select an Item",
            systemImage: "sidebar.left",
            description: Text("Choose an item from the sidebar to view details")
        )
    }
}

// MARK: - Previews
#Preview("Content View") {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

#Preview("Home View with Items") {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
        .onAppear {
            // Add sample data for preview
        }
}

#Preview("Empty Home View") {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
}