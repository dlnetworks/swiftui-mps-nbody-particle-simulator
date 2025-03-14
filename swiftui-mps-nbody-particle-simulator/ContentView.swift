import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var settings = SimulationSettings()
    @StateObject private var renderer = SimulationRenderer(settings: SimulationSettings())
    @State private var controlsOffset: CGFloat = -300
    @StateObject private var keyMonitor = KeyEventMonitor()

    init() {
        let shared = SimulationSettings()
        _settings = StateObject(wrappedValue: shared)
        _renderer = StateObject(wrappedValue: SimulationRenderer(settings: shared))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalView(settings: settings, renderer: renderer)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    setupKeyMonitor()
                }
                .onDisappear {
                    keyMonitor.stop()
                }
            
            Button(action: {
                let newOffset: CGFloat = controlsOffset == 0 ? -300 : 0
                controlsOffset = newOffset
            }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 12))
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.top, 10)
            .padding(.leading, 10)
            .zIndex(2)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Type", selection: $settings.simType) {
                        ForEach(SimulationSettings.SimulationType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Button(action: { settings.isRunning.toggle() }) {
                            Text(settings.isRunning ? "Pause Simulation" : "Start Simulation")
                                .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: { renderer.resetSimulation() }) {
                            Text("Restart")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Auto Mode Toggle and Interval Slider
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Auto Mode", isOn: $renderer.autoModeEnabled)
                            .onChange(of: renderer.autoModeEnabled) { newValue in
                                if newValue {
                                    // Start with a fresh restart when enabling
                                    renderer.autoRestartSimulation()
                                }
                            }
                        
                        if renderer.autoModeEnabled {
                            Text("Restart Every: \(String(format: "%.1f", renderer.autoRestartInterval)) minutes")
                                .font(.caption)
                            Slider(value: $renderer.autoRestartInterval, in: 1...10, step: 0.5)
                        }
                    }
                    
                    Button(action: { renderer.isOrbiting.toggle() }) {
                        Text(renderer.isOrbiting ? "Stop Camera Orbit" : "Start Camera Orbit")
                            .frame(maxWidth: .infinity)
                    }
                    
                    if renderer.isOrbiting {
                        Text("Orbit Speed: \(String(format: "%.2f", renderer.orbitSpeed))")
                        Slider(value: $renderer.orbitSpeed, in: 0.01...0.25)
                        
                        VStack(alignment: .leading) {
                            Text("Orbit Axes:").font(.caption).padding(.top, 4)
                            
                            HStack {
                                Toggle("X", isOn: $renderer.orbitX)
                                    .toggleStyle(CheckboxToggleStyle())
                                    .frame(maxWidth: 60)
                                
                                Toggle("Y", isOn: $renderer.orbitY)
                                    .toggleStyle(CheckboxToggleStyle())
                                    .frame(maxWidth: 60)
                                
                                Toggle("Z", isOn: $renderer.orbitZ)
                                    .toggleStyle(CheckboxToggleStyle())
                                    .frame(maxWidth: 60)
                            }
                        }
                    }
                    
                    Group {
                        
                        Text("Gravitational Force: \(String(format: "%.2f", settings.gravitationalForce))")
                        Slider(value: $settings.gravitationalForce, in: 0...20)
                        
                        Text("Number of Particles: \(settings.particleCount)")
                        Slider(value: Binding(
                            get: { Double(settings.particleCount) },
                            set: { settings.particleCount = Int($0) }),
                               in: 1000...100000)
                        
                        Text("Min Particle Size: \(String(format: "%.2f", settings.minParticleSize))")
                        Slider(value: $settings.minParticleSize, in: 0.01...1.0)
                            .onChange(of: settings.minParticleSize) { newValue in
                                if newValue >= settings.maxParticleSize {
                                    settings.maxParticleSize = newValue + 1
                                }
                            }
                        
                        Text("Max Particle Size: \(String(format: "%.2f", settings.maxParticleSize))")
                        Slider(value: $settings.maxParticleSize, in: 1.01...5.0)
                            .onChange(of: settings.maxParticleSize) { newValue in
                                if newValue <= settings.minParticleSize {
                                    settings.minParticleSize = newValue - 1
                                }
                            }
                        
                        Text("Galaxy Radius: \(Int(settings.radius))")
                        Slider(value: $settings.radius, in: 1...10000)
                        
                        Text("Disk Thickness: \(Int(settings.thickness))")
                        Slider(value: $settings.thickness, in: 0...settings.radius)
                        
                        Text("Initial Rotation: \(String(format: "%.2f", settings.initialRotation))")
                        Slider(value: $settings.initialRotation, in: 0...40)
                    }
                    .font(.caption)
                    
                    Group {
                        Text("Initial Core Spin: \(String(format: "%.2f", settings.initialCoreSpin))")
                        Slider(value: $settings.initialCoreSpin, in: 0...40)
                        
                        Text("Smoothing Length: \(String(format: "%.2f", settings.smoothing))")
                        Slider(value: $settings.smoothing, in: 0...100)
                        
                        Text("Interaction Rate: \(Int(settings.interactionRate * 100))%")
                        Slider(value: $settings.interactionRate, in: 0...1)
                        
                        
                    }
                    .font(.caption)
                    
                    if settings.simType == .collision {
                        Group {
                            Text("Collision Velocity: \(String(format: "%.2f", settings.collisionVelocity))")
                            Slider(value: $settings.collisionVelocity, in: 0...0.5)
                        }
                        .font(.caption)
                    }
                    
                    Group {
                     //   Text("Color Mix: \(String(format: "%.2f", settings.colorMix))")
                     //   Slider(value: $settings.colorMix, in: 0...1)
                        
                        HStack {
                            Toggle("Use Random Colors", isOn: $settings.useRandomColors)
                                .onChange(of: settings.useRandomColors) { newValue in
                                    if newValue {
                                        settings.generateRandomColors()
                                        renderer.updateParticleColors()
                                    }
                                }
                            
                            Button(action: {
                                settings.generateRandomColors()
                                renderer.updateParticleColors()
                            }) {
                                Text("New Colors")
                                    .frame(maxWidth: 100)
                            }
                            .disabled(!settings.useRandomColors)
                        }
                    }
                    
                    if settings.simType == .galaxy || settings.simType == .collision || settings.simType == .universe {
                        Toggle("Black Hole Enabled", isOn: $settings.blackHoleEnabled)
                        if settings.blackHoleEnabled {
                            Text("Black Hole Mass: \(Int(settings.blackHoleMass))")
                            Slider(value: $settings.blackHoleMass, in: 100...100000)
                            
                            // Add black hole spin slider with custom styling to show the 0 point
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Black Hole Spin: \(String(format: "%.3f", settings.blackHoleSpin))")
                                ZStack(alignment: .center) {
                                    Slider(value: $settings.blackHoleSpin, in: -0.05...0.05)
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 1, height: 10)
                                }
                                HStack {
                                    Text("Counter-Clockwise")
                                        .font(.system(size: 9))
                                    Spacer()
                                    Text("Clockwise")
                                        .font(.system(size: 9))
                                }
                            }
                        }
                    }
                    
                    if settings.simType == .collision {
                        Toggle("Second Black Hole Enabled", isOn: $settings.secondBlackHoleEnabled)
                        if settings.secondBlackHoleEnabled {
                            Text("Second Black Hole Mass: \(Int(settings.secondBlackHoleMass))")
                            Slider(value: $settings.secondBlackHoleMass, in: 100...100000)
                            
                            // Add second black hole spin slider with custom styling to show the 0 point
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Second Black Hole Spin: \(String(format: "%.3f", settings.secondBlackHoleSpin))")
                                ZStack(alignment: .center) {
                                    Slider(value: $settings.secondBlackHoleSpin, in: -0.05...0.05)
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 1, height: 10)
                                }
                                HStack {
                                    Text("Counter-Clockwise")
                                        .font(.system(size: 9))
                                    Spacer()
                                    Text("Clockwise")
                                        .font(.system(size: 9))
                                }
                            }
                            
                            if settings.blackHoleEnabled && settings.secondBlackHoleEnabled {
                                Text("Black Hole Interaction Gravity: \(String(format: "%.2f", settings.blackHoleGravityMultiplier))")
                                Slider(value: $settings.blackHoleGravityMultiplier, in: 0...10)
                            }
                        }
                    }
                }
                .padding(.top, 40)
                .padding()
            }
            .frame(width: 300, height: nil)
            .background(Color.black.opacity(0.6))
            .offset(x: controlsOffset, y: 0)
            .animation(nil, value: controlsOffset)
            .zIndex(1)
            .scrollIndicators(.never)
            

            
            VStack(alignment: .trailing) {
                Text("Particles: \(settings.particleCount)")
                Text("FPS: \(renderer.currentFPS)")
                if renderer.autoModeEnabled {
                    Text("Auto Mode: ON")
                        .foregroundColor(.green)
                }
            }
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color.white.opacity(0.5))
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .zIndex(2)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func setupKeyMonitor() {
        keyMonitor.onKeyDown = { key in
            if key.lowercased() == "r" {
                DispatchQueue.main.async {
                    self.renderer.resetSimulation()
                }
                return true
            } else if key.lowercased() == "c" && self.settings.useRandomColors {
                DispatchQueue.main.async {
                    print("Generating new colors on C key press")
                    self.settings.generateRandomColors()
                    self.renderer.updateParticleColors()
                }
                return true
            } else if key == " " {
                DispatchQueue.main.async {
                    self.settings.isRunning.toggle()
                }
                return true
            } else if key.lowercased() == "a" {
                DispatchQueue.main.async {
                    self.renderer.autoModeEnabled.toggle()
                    if self.renderer.autoModeEnabled {
                        // Start with a fresh restart when enabling with keyboard shortcut
                        self.renderer.autoRestartSimulation()
                    }
                }
                return true
            }
            return false
        }
        
        keyMonitor.start()
    }
}

// Global event monitor for key events
class KeyEventMonitor: ObservableObject {
    private var monitor: Any?
    var onKeyDown: ((String) -> Bool)?
    
    func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self,
                  let characters = event.characters,
                  let onKeyDown = self.onKeyDown else {
                return event
            }
            
            if onKeyDown(characters) {
                // Return nil to indicate the event was handled
                return nil
            }
            
            // Return the event to allow normal processing
            return event
        }
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    deinit {
        stop()
    }
}
