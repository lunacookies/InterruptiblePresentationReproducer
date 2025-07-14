import UIKit

final class CustomSheetExampleViewController: UIViewController {
	private var customSheetTransitioningDelegate = CustomSheetTransitioningDelegate()

	override func loadView() {
		super.loadView()
		view.backgroundColor = .systemBackground

		var configuration = UIButton.Configuration.borderedProminent()
		configuration.buttonSize = .large
		let button = UIButton(
			configuration: configuration,
			primaryAction: UIAction(title: "Present") { [weak self] _ in
				guard let self else { return }
				didTapButton()
			},
		)

		view.embed(centered: button)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Custom Sheet"
	}

	private func didTapButton() {
		let presentedViewController = UINavigationController(rootViewController: ContentViewController())
		presentedViewController.modalPresentationStyle = .custom
		presentedViewController.transitioningDelegate = customSheetTransitioningDelegate
		present(presentedViewController, animated: true)
	}

	private final class ContentViewController: UIViewController {
		override func loadView() {
			super.loadView()
			view.backgroundColor = .systemBackground
			let label = UILabel()
			label.text = "Hello World"
			view.embed(centered: label)
		}

		override func viewDidLoad() {
			super.viewDidLoad()
			title = "Presentation Content"
			navigationItem.rightBarButtonItem = UIBarButtonItem(
				systemItem: .close,
				primaryAction: UIAction { [weak self] _ in
					guard let self else { return }
					dismiss(animated: true)
				},
			)
		}
	}
}

private final class CustomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
	private var presentationController: CustomSheetPresentationController?

	func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source _: UIViewController,
	) -> UIPresentationController? {
		presentationController = CustomSheetPresentationController(
			presentedViewController: presented,
			presenting: presenting,
		)
		return presentationController!
	}

	func animationController(
		forPresented _: UIViewController,
		presenting _: UIViewController,
		source _: UIViewController,
	) -> (any UIViewControllerAnimatedTransitioning)? {
		presentationController!.operation = .present
		return presentationController!
	}

	func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
		presentationController!.operation = .dismiss
		return presentationController!
	}

	func interactionControllerForPresentation(using _: any UIViewControllerAnimatedTransitioning)
		-> (any UIViewControllerInteractiveTransitioning)?
	{
		presentationController!.operation = .present
		return presentationController!
	}

	func interactionControllerForDismissal(using _: any UIViewControllerAnimatedTransitioning)
		-> (any UIViewControllerInteractiveTransitioning)?
	{
		presentationController!.operation = .dismiss
		return presentationController!
	}
}

private final class CustomSheetPresentationController: UIPresentationController {
	var operation: Operation?

	private var dimmingView: UIView!
	private var transitionContext: (any UIViewControllerContextTransitioning)!
	private let animator = UIViewPropertyAnimator(
		duration: 0,
		timingParameters: UISpringTimingParameters(duration: 0.5, bounce: 0.3),
	)

	override func presentationTransitionWillBegin() {
		let containerView = containerView!
		let presentedView = presentedView!

		dimmingView = UIView()
		dimmingView.backgroundColor = .black
		containerView.embed(dimmingView)
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView(_:)))
		dimmingView.addGestureRecognizer(tapGestureRecognizer)

		presentedView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(presentedView)

		NSLayoutConstraint.activate([
			presentedView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			presentedView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			presentedView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
			presentedView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 1 / 3),
		])

		configure(for: .dismiss)
	}

	@objc
	private func didTapDimmingView(_: UITapGestureRecognizer) {
		guard animator.isRunning else {
			presentedViewController.dismiss(animated: true)
			return
		}

		transitionContext.cancelInteractiveTransition()
		operation = .dismiss
		animate()
	}

	private func animate() {
		animator.addAnimations { [self] in configure(for: operation!) }
		animator.addCompletion { [self] _ in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
			if operation == .dismiss {
				presentedViewController.dismiss(animated: true)
			}
		}
	}

	private func configure(for operation: Operation) {
		let presentedView = presentedView!

		switch operation {
		case .present:
			presentedView.transform = .identity
			dimmingView.alpha = 0.5

		case .dismiss:
			containerView!.layoutIfNeeded()
			presentedView.transform = CGAffineTransform(translationX: 0, y: presentedView.frame.height)
			dimmingView.alpha = 0
		}
	}

	enum Operation {
		case present
		case dismiss
	}
}

extension CustomSheetPresentationController: UIViewControllerAnimatedTransitioning {
	func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
		animator.duration
	}

	func animateTransition(using _: any UIViewControllerContextTransitioning) {
		fatalError()
	}
}

extension CustomSheetPresentationController: UIViewControllerInteractiveTransitioning {
	func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
		self.transitionContext = transitionContext
		animate()
		animator.startAnimation()
	}
}
