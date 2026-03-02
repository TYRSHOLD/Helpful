import SwiftUI

struct OpportunityDiscoverView: View {

    @Environment(OpportunityViewModel.self) var vm
    @State private var filterIndex = 0

    private var selectedType: OpportunityType? {
        switch filterIndex {
        case 1: return .scholarship
        case 2: return .internship
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterPicker
            cardStackArea
            actionButtons
        }
        .task { await vm.fetchOpportunities(type: selectedType, reset: true) }
        .onChange(of: filterIndex) { _, _ in
            Task { await vm.fetchOpportunities(type: selectedType, reset: true) }
        }
    }

    // MARK: - Filter

    private var filterPicker: some View {
        Picker("Filter", selection: $filterIndex) {
            Text("All").tag(0)
            Text("Scholarships").tag(1)
            Text("Internships").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Card Stack

    private var cardStackArea: some View {
        ZStack {
            if vm.isLoading && vm.cardStack.isEmpty {
                loadingState
            } else if let error = vm.errorMessage, vm.cardStack.isEmpty {
                errorState(message: error)
            } else if vm.cardStack.isEmpty {
                emptyState
            } else {
                cardStack
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardStack: some View {
        ZStack {
            ForEach(Array(vm.cardStack.prefix(3).enumerated().reversed()), id: \.element.externalId) { index, opportunity in
                SwipeableCardView(opportunity: opportunity) { direction in
                    Task {
                        switch direction {
                        case .right:
                            await vm.save(opportunity)
                        case .left:
                            await vm.dismiss(opportunity)
                        }
                        await vm.loadMoreIfNeeded(type: selectedType)
                    }
                }
                .scaleEffect(scaleFor(index: index))
                .offset(y: offsetFor(index: index))
                .allowsHitTesting(index == 0)
            }
        }
        .padding(.horizontal, 16)
    }

    private func scaleFor(index: Int) -> CGFloat {
        1.0 - CGFloat(index) * 0.04
    }

    private func offsetFor(index: Int) -> CGFloat {
        CGFloat(index) * 8
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 24) {
            Button {
                guard let top = vm.cardStack.first else { return }
                Task {
                    await vm.dismiss(top)
                    await vm.loadMoreIfNeeded(type: selectedType)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AppColors.coral)
                    .clipShape(Circle())
                    .shadow(color: AppColors.coral.opacity(0.3), radius: 6, y: 3)
            }
            .disabled(vm.cardStack.isEmpty)
            .opacity(vm.cardStack.isEmpty ? 0.4 : 1)

            Button {
                Task { await vm.undoLastDismiss() }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.body.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.yellow)
                    .clipShape(Circle())
                    .shadow(color: AppColors.yellow.opacity(0.3), radius: 6, y: 3)
            }
            .disabled(!vm.canUndo)
            .opacity(vm.canUndo ? 1 : 0.4)

            Button {
                guard let top = vm.cardStack.first else { return }
                Task {
                    await vm.save(top)
                    await vm.loadMoreIfNeeded(type: selectedType)
                }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(AppColors.green)
                    .clipShape(Circle())
                    .shadow(color: AppColors.green.opacity(0.3), radius: 6, y: 3)
            }
            .disabled(vm.cardStack.isEmpty)
            .opacity(vm.cardStack.isEmpty ? 0.4 : 1)
        }
        .padding(.vertical, 16)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding opportunities...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.yellow)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                Task { await vm.fetchOpportunities(type: selectedType, reset: true) }
            }
            .buttonStyle(GradientButtonStyle())
            .padding(.horizontal, 60)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.purple)
            Text("You've seen them all!")
                .font(.headline)
            Text("Check back later for new opportunities")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Refresh") {
                Task { await vm.fetchOpportunities(type: selectedType, reset: true) }
            }
            .buttonStyle(GradientButtonStyle(gradient: AppGradients.purple))
            .padding(.horizontal, 60)
            .padding(.top, 8)
        }
    }
}
