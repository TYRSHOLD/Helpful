import SwiftUI

enum SwipeDirection {
    case left, right
}

struct SwipeableCardView: View {

    let opportunity: Opportunity
    let onSwiped: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 150

    var body: some View {
        GeometryReader { geo in
            cardContent
                .frame(width: geo.size.width - 32, height: geo.size.height - 32)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .offset(x: offset.width, y: offset.height * 0.3)
        .rotationEffect(.degrees(Double(offset.width / 25)))
        .gesture(dragGesture)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: offset)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.green.opacity(saveOverlayOpacity))

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.coral.opacity(passOverlayOpacity))

            VStack(spacing: 0) {
                headerSection
                Divider().padding(.horizontal)
                bodySection
                Spacer(minLength: 8)
                footerSection
            }
            .padding(20)

            overlayLabels
        }
    }

    // MARK: - Overlay Labels

    private var overlayLabels: some View {
        ZStack {
            Text("SAVE")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(AppColors.green)
                .rotationEffect(.degrees(-15))
                .opacity(saveOverlayOpacity * 2)
                .padding(.trailing, 80)

            Text("PASS")
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(AppColors.coral)
                .rotationEffect(.degrees(15))
                .opacity(passOverlayOpacity * 2)
                .padding(.leading, 80)
        }
    }

    private var saveOverlayOpacity: Double {
        max(0, min(Double(offset.width) / Double(swipeThreshold), 0.6))
    }

    private var passOverlayOpacity: Double {
        max(0, min(Double(-offset.width) / Double(swipeThreshold), 0.6))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: opportunity.type.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(opportunity.type.color)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(opportunity.employer)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text(opportunity.location)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }

                Spacer()

                typeBadge
            }

            Text(opportunity.title)
                .font(.title3.bold())
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 12)
    }

    private var typeBadge: some View {
        Text(opportunity.type.rawValue)
            .font(.caption.bold())
            .foregroundStyle(opportunity.type.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(opportunity.type.color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Body

    private var bodySection: some View {
        ScrollView {
            Text(opportunity.descriptionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Label {
                Text(opportunity.datePosted, style: .date)
            } icon: {
                Image(systemName: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                    .foregroundStyle(AppColors.coral.opacity(0.5))
                Text("swipe")
                    .foregroundStyle(.tertiary)
                Image(systemName: "arrow.right")
                    .foregroundStyle(AppColors.green.opacity(0.5))
            }
            .font(.caption2)
        }
        .padding(.top, 8)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
                if value.translation.width > swipeThreshold {
                    swipeOff(direction: .right)
                } else if value.translation.width < -swipeThreshold {
                    swipeOff(direction: .left)
                } else {
                    offset = .zero
                }
            }
    }

    private func swipeOff(direction: SwipeDirection) {
        let flyX: CGFloat = direction == .right ? 600 : -600
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(width: flyX, height: offset.height)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSwiped(direction)
        }
    }
}
