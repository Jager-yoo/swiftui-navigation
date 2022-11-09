import CustomDump
import SwiftUI

/// A data type that describes the state of a confirmation dialog that can be shown to the user. The
/// `Action` generic is the type of actions that can be sent from tapping on a button in the sheet.
///
/// This type can be used in your application's state in order to control the presentation and
/// actions of dialogs. This API can be used to push the logic of alert presentation and action into
/// your model, making it easier to test, and simplifying your view layer.
///
/// To use this API, you describe all of a dialog's actions as cases in an enum:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   enum ConfirmationDialogAction {
///     case deleteButtonTapped
///     case favoriteButtonTapped
///   }
///   // ...
/// }
/// ```
///
/// You model the state for showing the alert in as a published field, which can start off `nil`:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   // ...
///   @Published var dialog: ConfirmationDialogState<ConfirmationDialogAction>?
///   // ...
/// }
/// ```
///
/// And you define an endpoint for handling each alert action:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   // ...
///   func dialogButtonTapped(_ action: ConfirmationDialogAction) {
///     switch action {
///     case .deleteButtonTapped:
///       // ...
///     case .favoriteButtonTapped:
///       // ...
///     }
///   }
/// }
/// ```
///
/// Then, in an endpoint that should display an alert, you can construct a
/// ``ConfirmationDialogState`` value to represent it:
///
/// ```swift
/// class ItemModel: ObservableObject {
///   // ...
///   func infoButtonTapped() {
///     self.dialog = ConfirmationDialogState(
///       title: "What would you like to do?",
///       buttons: [
///         .default(TextState("Favorite"), action: .send(.favoriteButtonTapped)),
///         .destructive(TextState("Delete"), action: .send(.deleteButtonTapped)),
///         .cancel(TextState("Cancel")),
///       ]
///     )
///   }
/// }
/// ```
///
/// And in your view you can use the `.confirmationDialog(unwrapping:action:)` view modifier to
/// present the dialog:
///
/// ```swift
/// struct ItemView: View {
///   @ObservedObject var model: ItemModel
///
///   var body: some View {
///     VStack {
///       Button("Info") {
///         self.model.infoButtonTapped()
///       }
///     }
///     .confirmationDialog(unwrapping: self.$model.dialog) { action in
///       self.model.dialogButtonTapped(action)
///     }
///   }
/// }
/// ```
///
/// This makes your model in complete control of when the alert is shown or dismissed, and makes it
/// so that any choice made in the alert is automatically fed back into the model so that you can
/// handle its logic.
///
/// Even better, you can instantly write tests that your alert behavior works as expected:
///
/// ```swift
/// let model = ItemModel()
///
/// model.infoButtonTapped()
/// XCTAssertEqual(
///   model.dialog,
///   ConfirmationDialogState(
///     title: "What would you like to do?",
///     buttons: [
///       .default(TextState("Favorite"), action: .send(.favoriteButtonTapped)),
///       .destructive(TextState("Delete"), action: .send(.deleteButtonTapped)),
///       .cancel(TextState("Cancel")),
///     ]
///   )
/// )
///
/// model.dialogButtonTapped(.favoriteButtonTapped)
/// // Verify that favorite logic executed correctly
/// model.dialog = nil
/// ```
@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
public struct ConfirmationDialogState<Action> {
  public let id = UUID()
  public var buttons: [Button]
  public var message: TextState?
  public var title: TextState
  public var titleVisibility: Visibility

  @available(iOS 15, *)
  @available(macOS 12, *)
  @available(tvOS 15, *)
  @available(watchOS 8, *)
  public init(
    title: TextState,
    titleVisibility: Visibility,
    message: TextState? = nil,
    buttons: [Button] = []
  ) {
    self.buttons = buttons
    self.message = message
    self.title = title
    self.titleVisibility = titleVisibility
  }

  public init(
    title: TextState,
    message: TextState? = nil,
    buttons: [Button] = []
  ) {
    self.buttons = buttons
    self.message = message
    self.title = title
    self.titleVisibility = .automatic
  }

  public typealias Button = AlertState<Action>.Button

  public enum Visibility {
    case automatic
    case hidden
    case visible
  }
}

@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
extension ConfirmationDialogState: CustomDumpReflectable {
  public var customDumpMirror: Mirror {
    Mirror(
      self,
      children: [
        "title": self.title,
        "message": self.message as Any,
        "buttons": self.buttons,
      ],
      displayStyle: .struct
    )
  }
}

@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
extension ConfirmationDialogState: Equatable where Action: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.title == rhs.title
    && lhs.message == rhs.message
    && lhs.buttons == rhs.buttons
  }
}

@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
extension ConfirmationDialogState: Hashable where Action: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.title)
    hasher.combine(self.message)
    hasher.combine(self.buttons)
  }
}

@available(iOS 13, *)
@available(macOS 12, *)
@available(tvOS 13, *)
@available(watchOS 6, *)
extension ConfirmationDialogState: Identifiable {}

@available(iOS, introduced: 13, deprecated: 100000.0, message: "use `View.confirmationDialog(title:isPresented:titleVisibility:presenting::actions:)`instead.")
@available(macOS, unavailable)
@available(tvOS, introduced: 13, deprecated: 100000.0, message: "use `View.confirmationDialog(title:isPresented:titleVisibility:presenting:actions:)`instead.")
@available(watchOS, introduced: 6, deprecated: 100000.0, message: "use `View.confirmationDialog(title:isPresented:titleVisibility:presenting:actions:)`instead.")
extension ActionSheet {
  public init<Action>(
    _ state: ConfirmationDialogState<Action>,
    action: @escaping (Action) -> Void
  ) {
    self.init(
      title: Text(state.title),
      message: state.message.map { Text($0) },
      buttons: state.buttons.map { .init($0, action: action) }
    )
  }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
extension Visibility {
  public init<Action>(_ visibility: ConfirmationDialogState<Action>.Visibility) {
    switch visibility {
    case .automatic:
      self = .automatic
    case .hidden:
      self = .hidden
    case .visible:
      self = .visible
    }
  }
}