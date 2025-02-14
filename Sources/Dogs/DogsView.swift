//
//  DogsView.swift
//  
//
//  Created by kwanghyun won on 2021/08/20.
//

import SwiftUI
import ComposableArchitecture

/// Dogs View

public struct DogsView: View {
  public init(
    store: Store<DogsView.ViewState, DogsView.ViewAction>
  ) {
    self.store = store
  }
  
  public let store: Store<ViewState, ViewAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        if viewStore.loadingState.isLoading {
          ProgressView()
        } else {
          searchBar(for: viewStore)
          breedsList(for: viewStore)
        }
      }
      .navigationTitle("Dogs")
      .padding()
      .onAppear { viewStore.send(.onAppear) }
    }
  }
  
  @ViewBuilder
  private func searchBar(for viewStore: ViewStore<ViewState, ViewAction>) -> some View {
    HStack {
      Image(systemName: "magnifyingglass")
      TextField(
        "Filter breeds",
        text: viewStore.binding(
          get: \.filterText,
          send: ViewAction.filterTextChanged
        )
      )
      .textFieldStyle(RoundedBorderTextFieldStyle())
      .autocapitalization(.none)
      .disableAutocorrection(true)
    }
  }
  
  @ViewBuilder
  private func breedsList(for viewStore: ViewStore<ViewState, ViewAction>) -> some View {
    ScrollView {
      // 1.
      ForEach(viewStore.loadingState.breeds, id: \.self) { breed in
        VStack {
          // 2.
          Button(action: { viewStore.send(.cellWasSelected(breed: breed)) }) {
            HStack {
              Text(breed)
              Spacer()
              Image(systemName: "chevron.right")
            }
          }
          Divider()
        }
        .foregroundColor(.primary)
      }
    }
    .padding()
  }
}

/// ViewState
extension DogsView {
  public struct ViewState: Equatable {
    let filterText: String
    let loadingState: LoadingState
  }
}

extension DogsView.ViewState {
  enum LoadingState: Equatable {
    case loading
    case loaded(breed: [String])
    
    var breeds: [String] {
      guard case .loaded(let breeds) = self else { return [] }
      return breeds
    }
    
    var isLoading: Bool { self == .loading }
  }
  
  // state를 viewState로 변환 (adapter pattern)
  static func convert(from state: DogsState) -> Self {
    .init(
      filterText: state.filterQuery,
      loadingState: loadingState(from: state)
    )
  }
  
  private static func loadingState(from state: DogsState) -> LoadingState {
    if state.dogs.isEmpty { return .loading }
    
    // 아래는 비즈니스로직과는 상관없는 뷰로직
    // 이런식으로 분리하면 테스트에 유리하다
    var breeds = state.dogs.map(\.breed.capitalizedFirstLetter)
    if !state.filterQuery.isEmpty {
      breeds = breeds.filter {
        $0.lowercased().contains(state.filterQuery.lowercased())
      }
    }
    
    return .loaded(breed: breeds)
  }
}

extension DogsView {
  public enum ViewAction: Equatable {
    case cellWasSelected(breed: String)
    case onAppear
    case filterTextChanged(String)
  }
}



struct DogsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      DogsView(
        store: Store(
          initialState: DogsState.initial,
          reducer: DogsState.reducer,
          environment: DogsEnvironment.fake
        )
        .scope(state: \.view, action: DogsAction.view)
      )
    }
    
    NavigationView {
      DogsView(
        store: Store(
          initialState: DogsView.ViewState(
            filterText: "",
            loadingState: .loading
          ),
          reducer: .empty,
          environment: ()))
    }
  }
}
