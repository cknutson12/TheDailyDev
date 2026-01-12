# Tour Highlighting Improvement Plan

## Current Issues

1. **Frame Detection Problems:**
   - Toolbar items (Settings, Analytics) are in a different coordinate space
   - Global coordinates from `GeometryReader` don't match toolbar item positions
   - Frame detection is unreliable for navigation bar elements

2. **UX Problems:**
   - Black overlay blocks the entire screen (too aggressive)
   - Circle cutout doesn't match actual button shapes (rectangular buttons)
   - Highlighting appears in wrong location (not where buttons actually are)
   - Users can't see context around highlighted elements

3. **Visual Design Problems:**
   - Circle spotlight doesn't match rectangular UI elements
   - Too much visual noise with black overlay
   - Glow effect is not prominent enough

## Proposed Solution

### Approach: Direct Element Highlighting (No Overlay)

Instead of blacking out the screen and cutting a hole, we'll:
1. **Add a subtle glow directly to the target element** using a view modifier
2. **Use proper coordinate space conversion** for accurate frame detection
3. **Create a pulsing border/glow effect** that matches the element's actual shape
4. **Keep the tooltip overlay** but remove the black background

### Implementation Strategy

#### Phase 1: Fix Frame Detection
- Use `coordinateSpace(name:)` to create a named coordinate space
- Convert frames from local to global coordinate space properly
- For toolbar items, use a different approach (maybe highlight the entire toolbar area or use a custom overlay)

#### Phase 2: New Highlighting System
- Create a `TourHighlightModifier` that adds a glowing border directly to views
- Use a pulsing animation to draw attention
- Match the shape of the element (rounded rectangle for buttons, etc.)
- Use the app's accent green color with opacity

#### Phase 3: Simplified Overlay
- Remove the black overlay entirely
- Keep only the tooltip at the bottom
- Let the highlighted element speak for itself

### Technical Details

#### Frame Detection Improvements
```swift
// Use named coordinate space for accurate frame tracking
.coordinateSpace(name: "tourSpace")
.framePreference(key: ViewFramePreferenceKey.self, value: identifier)

// Convert to global coordinates properly
let globalFrame = geometry.frame(in: .named("tourSpace"))
```

#### Direct Highlight Modifier
```swift
struct TourHighlightModifier: ViewModifier {
    let isActive: Bool
    let glowColor: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(glowColor, lineWidth: 3)
                    .shadow(color: glowColor.opacity(0.8), radius: 10)
                    .opacity(isActive ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
            )
    }
}
```

#### Toolbar Item Handling
For toolbar items, we'll:
- Option 1: Highlight the entire toolbar area with a subtle background
- Option 2: Use a custom overlay positioned at the toolbar location
- Option 3: Add a badge/indicator near the toolbar items

### UX Design Principles

1. **Subtle but Clear:** The highlight should be noticeable but not overwhelming
2. **Context Preservation:** Users should see the full screen context
3. **Shape Matching:** Highlight should match the actual element shape
4. **Smooth Animation:** Gentle pulsing animation to draw attention
5. **Color Consistency:** Use app's accent green for familiarity

### Visual Design

- **Glow Effect:**
  - Green border (3-4px) matching accent color
  - Soft shadow with green tint
  - Opacity: 0.8-1.0 for visibility
  - Pulsing animation: 1-1.1 scale, 1 second duration

- **Tooltip:**
  - Keep at bottom of screen
  - Remove black background
  - Use semi-transparent card with blur effect
  - Arrow pointing to highlighted element

### Implementation Steps

1. **Create TourHighlightModifier** - Direct glow effect on elements
2. **Fix coordinate space conversion** - Proper frame detection
3. **Update ViewFramePreferenceKey** - Better coordinate handling
4. **Create toolbar-specific highlighting** - Special handling for nav bar items
5. **Update TourOverlayView** - Remove black overlay, keep tooltip
6. **Test on all target elements** - Daily button, Settings, Analytics, History, Performance

### Testing Checklist

- [ ] Daily question button highlights correctly
- [ ] Settings button highlights correctly (toolbar)
- [ ] Analytics button highlights correctly (toolbar)
- [ ] Question history grid highlights correctly
- [ ] Performance view highlights correctly
- [ ] Highlight matches element shape
- [ ] Pulsing animation is smooth
- [ ] No black overlay blocking view
- [ ] Tooltip is clear and readable
- [ ] Works on different screen sizes

### Alternative Approaches (If Needed)

**Option A: Badge/Indicator System**
- Add a small animated badge near target elements
- Less intrusive than glow
- Works well for toolbar items

**Option B: Spotlight with Gradient**
- Use a gradient spotlight instead of solid black
- More subtle, preserves visibility
- Still uses cutout approach but softer

**Option C: Outline Only**
- Just a border outline, no glow
- Minimalist approach
- Very subtle

## Recommendation

**Go with Direct Element Highlighting (Phase 2 approach):**
- Most intuitive for users
- Preserves full screen context
- Matches element shapes naturally
- Easier to implement correctly
- Better UX overall

