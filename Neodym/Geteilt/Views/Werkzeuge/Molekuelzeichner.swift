//
//  Molekuelzeichner.swift
//  Neodym
//
//  Created by Max Eckstein on 06.06.23.
//

import SwiftUI
import GameKit
#if os(iOS) || os(visionOS)
import PencilKit
#endif

struct Molekuelzeichner: View {
    
    @Environment(Elemente.self) private var elemente
    @Binding var columnVisibility: NavigationSplitViewVisibility
    
    // Sheets
    @State private var zeigeHinzufuegen = false
    @State private var zeigeEinstellungen = false
    
    @State private var canvasObjekte: [CanvasObjekt] = []
    @State private var canvasBindungen: [CanvasBindung] = []
    
    @State private var ursprungDesLassos: CGPoint? = nil
    @State private var aktuellerOrtDerLassos: CGPoint? = nil
    
    @State private var ausgewaelteObjekte: [UUID] = []
    @State private var ausgehendesElektron: Int?
    
    @State private var ausgewaeltesWerkzeug: Werkzeug = .fingerOderZeiger
    
    @State private var ortDesCanvas: CGSize = .zero
    @State private var aktuelleVerschiebung: CGSize = .zero // Die schon einberechnet ist
    
    @State private var initialeDrehungen: [Int: Angle]? = nil
    @State private var initialePositionen: [Int: CGPoint]? = nil
    @State private var drehAnkerPunkt: CGPoint? = nil
        
    // Kopieren und Einfügen
    @State private var zwischenSpeicherObjekte = [CanvasObjekt]()
    @State private var zwischenSpeicherBindungen = [CanvasBindung]()
    @State private var wieOftEingefuegtOhneNeuZuKopieren = 0
    
    // Wenn eine neue Bindung durch das ziehen von einem Elektron erzeugt wird
    @State private var startPunkt: CGPoint? = nil
    @State private var aktuellerOrtDesElektrons: CGPoint? = nil
    @State private var elektronWurdeZuendeGezogen = false
    @State private var anderesElektron: (UUID, Int)? = nil
    
    // Konfigurationen
    @AppStorage("reduzierteSchreibweise") private var reduzierteSchreibweise = true
    @AppStorage("oxEinblenden")     private var oxzahlenEinblenden = true
    @AppStorage("keileEinblenden")  private var keileEinblenden = false
    @AppStorage("winkelEinblenden") private var winkelEinblenden = false
    @AppStorage("zoom")             private var zoom = 1.0
    @AppStorage("atomDarstellung")  private var atomDarstellung = "hintergrund"
    @AppStorage("hintergrund")      private var hintergrund = "karo"
    @State                          private var letzterZoom = 1.0
    
    // Tastatur
    @FocusState private var focused: Bool
    @State      private var shiftIstGedrueckt   = false
    
    @State private var aktuelleAktion: NutzerAktion? = nil
    
    #if os(iOS) || os(visionOS)
    // Zeichnen
    var picker = PKToolPicker()
    var zeichenflaeche = PKCanvasView()
    #endif
    
    // Das Symbol des zuletzt hinzugefügten Atoms
    @State private var letztesAtomSymbol = "C"
    
    private let canvasGroesse: CGFloat = 3_500
    
    var body: some View {
        HOrVStack(
            Group {
            Text("")
                .frame(width: 0, height: 0)
                .focusable()
                .focused($focused)
                .onKeyPress { press in
                    // Funktioniert nur auf macOS
                    if press.key == .delete {
                        loescheElemente()
                        return .handled
                    } else {
                        return .ignored
                    }
                }
                .onAppear {
                    focused = true
                }
            Group {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    iPhoneControlls
                } else {
                    iPadControlls
                }
#else
                iPadControlls
#endif
            }
            .navigationTitle("Molekül Canvas")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.bgr, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                Button {
                    
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }.disabled(true)
                Button {
                    zeigeEinstellungen = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }.popover(isPresented: $zeigeEinstellungen) {
                    einstellungen
                }
            }
            .zIndex(1.0)
            Divider()
                .background(.indigo)
            canvas
                .clipped()
                .ignoresSafeArea(.all)
                .zIndex(0)
        })
        .onChange(of: focused) { oldValue, newValue in
            print(newValue)
        }
    }
    
    var canvas: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                Color.bgr
                if hintergrund != "" {
                    Image(hintergrund)
                        .renderingMode(.template)
                        .resizable(resizingMode: .tile)
                        .foregroundStyle(.gray.opacity(0.3))
                        .frame(width: canvasGroesse, height: canvasGroesse)
                }
                // Kreuz im Hintergrund
                ZStack (alignment: .center){
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [10]))
                        .fill(Color.indigo)
                        .frame(height: 1)
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [10]))
                        .fill(Color.indigo)
                        .frame(height: 1)
                        .rotationEffect(Angle(degrees: 90))
                }
                .frame(width: 70, height: 70)
                #if os(iOS) || os(visionOS)
                ZeichenFlaeche(aktiv: ausgewaeltesWerkzeug == .zeichnen, zeichenflaeche: zeichenflaeche, picker: picker)
                    .frame(width: canvasGroesse, height: canvasGroesse)
                    .zIndex(ausgewaeltesWerkzeug == .zeichnen ? 0.6 : 0.4)
                #endif
                ZStack (alignment: .center) {
                    // Bei Lasso der ausgewählte Bereich
                    if ausgewaeltesWerkzeug == .lasso && ursprungDesLassos != nil && aktuellerOrtDerLassos != nil {
                        let breite = ursprungDesLassos!.x - aktuellerOrtDerLassos!.x
                        let hoehe = ursprungDesLassos!.y - aktuellerOrtDerLassos!.y
                        Color
                            .blue
                            .opacity(0.3)
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.blue, lineWidth: 1))
                            .frame(width: abs(breite), height: abs(hoehe))
                            .offset(x: ursprungDesLassos!.x - breite / 2, y: ursprungDesLassos!.y - hoehe / 2)
                    }
                    
                    // Bindungen der Canvas Objekte
                    ForEach(canvasBindungen) { bindung in
                        bindungAufCanvas(bindung)
                    }
                    
                    // Gezogene Bindungen
                    if aktuellerOrtDesElektrons != nil {
                        temporaereBindungWegenGezogenemElektron()
                    }
                    
                    // Canvas Objekte
                    ForEach(canvasObjekte) { objekt in
                        elementAufCanvas(objekt)
                            .offset(x: objekt.ort.x, y: objekt.ort.y)
                            .gesture(
                                DragGesture()
                                    .onChanged({ value in
                                        if (aktuelleAktion == nil || aktuelleAktion == .verschiebtElemente){
                                            aktuelleAktion = .verschiebtElemente
                                            if !ausgewaelteObjekte.contains(objekt.id) {
                                                if ausgewaeltesWerkzeug == .lasso {
                                                    ausgewaelteObjekte.append(objekt.id)
                                                } else {
                                                    ausgewaelteObjekte = [objekt.id]
                                                }
                                            }
                                            for i in ausgewaelteObjekte {
                                                guard let objektIndex = canvasObjekte.firstIndex(where: { x in x.id == i}) else { continue }
                                                let neueXPos = canvasObjekte[objektIndex].ort.x + (value.translation.width - aktuelleVerschiebung.width)
                                                let neueYPos = canvasObjekte[objektIndex].ort.y + (value.translation.height - aktuelleVerschiebung.height)
                                                if abs(neueXPos) < canvasGroesse / 2 - 60 {
                                                    canvasObjekte[objektIndex].ort.x = neueXPos
                                                }
                                                if abs(neueYPos) < canvasGroesse / 2 - 60 {
                                                    canvasObjekte[objektIndex].ort.y = neueYPos
                                                }
                                            }
                                            aktuelleVerschiebung = value.translation
                                        }
                                    })
                                    .onEnded({ _ in
                                        aktuelleVerschiebung = .zero
                                        if aktuelleAktion == .verschiebtElemente {
                                            aktuelleAktion = nil
                                        }
                                    })
                            )
                    }
                    
                }
                    .frame(width: canvasGroesse, height: canvasGroesse)
                    .zIndex(0.5)
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .offset(ortDesCanvas)
            .scaleEffect(zoom)
            .frame(width: geo.size.width, height: geo.size.height)
            .gesture(
                ausgewaeltesWerkzeug == .zeichnen ? nil :
                    DragGesture()
                    .onChanged({ value in
                        if (aktuelleAktion == nil || aktuelleAktion == .verschiebtCanvasOderLasso){
                            aktuelleAktion = .verschiebtCanvasOderLasso
                            // Falls das Lasso ausgewählt ist, soll ein Auswahlbereich entstehen
                            if ausgewaeltesWerkzeug == .lasso {
                                // Die tatsächliche Position auf dem Canvas
                                let x = (value.location.x - geo.size.width / 2) / zoom - ortDesCanvas.width
                                let y = (value.location.y - geo.size.height / 2) / zoom - ortDesCanvas.height
                                
                                aktuellerOrtDerLassos = CGPointMake(x, y)
                                
                                // Falls der Ursprung noch nicht definiert ist, soll er definiert werden als die aktuelle Position
                                if ursprungDesLassos == nil {
                                    ursprungDesLassos = CGPointMake(x, y)
                                }
                            } else {
                                // Sonst soll der Canvas verschoben werden
                                let x = ortDesCanvas.width + (value.translation.width - aktuelleVerschiebung.width) / zoom
                                let y = ortDesCanvas.height + (value.translation.height - aktuelleVerschiebung.height) / zoom
                                if abs(x) + geo.size.width / (2*zoom) < canvasGroesse / 2 {
                                    ortDesCanvas.width = x
                                }
                                if abs(y) + geo.size.height / (2*zoom) < canvasGroesse / 2 {
                                    ortDesCanvas.height = y
                                }
                                aktuelleVerschiebung = value.translation
                            }
                        }
                    })
                    .onEnded({ _ in
                        if ausgewaeltesWerkzeug == .lasso {
                            markiereAlleImAusgewaeltenBereich()
                            ursprungDesLassos = nil
                            aktuellerOrtDerLassos = nil
                        }
                        if aktuelleAktion == .verschiebtCanvasOderLasso {
                            aktuelleAktion = nil
                        }
                        aktuelleVerschiebung = .zero
                    })
            )
            .gesture(MagnificationGesture(minimumScaleDelta: 0.05)
                .onChanged { neuerZoom in
                    if (aktuelleAktion == nil || aktuelleAktion == .vergroessern) {
                        aktuelleAktion = .vergroessern
                        let delta = neuerZoom / letzterZoom
                        let neuerZoomAusgerechnet = min(max(zoom * delta, 0.5), 2.0)
                        zoom = neuerZoomAusgerechnet
                        letzterZoom = neuerZoom
                        if delta < 1 {
                            // Rausgezoomt
                            // Prüfen, ob der Canvas verschoben werden muss, um  in seinen Grenzen zu bleiben
                            let xDelta = canvasGroesse / 2 - (abs(ortDesCanvas.width) + geo.size.width / (2*zoom))
                            if xDelta < 0 {
                                if ortDesCanvas.width < 0 {
                                    ortDesCanvas.width -= xDelta
                                } else {
                                    ortDesCanvas.width += xDelta
                                }
                            }
                            let yDelta = canvasGroesse / 2 - (abs(ortDesCanvas.height) + geo.size.height / (2*zoom))
                            if yDelta < 0 {
                                if ortDesCanvas.height < 0 {
                                    ortDesCanvas.height -= yDelta
                                } else {
                                    ortDesCanvas.height += yDelta
                                }
                            }
                        }
                    }
                }
                .onEnded({ _ in
                    if aktuelleAktion == .vergroessern {
                        letzterZoom = 1.0
                        aktuelleAktion = nil
                    }
                })
                    .simultaneously(with: RotationGesture()
                        .onChanged({ gesture in
                            if (aktuelleAktion == nil || aktuelleAktion == .drehen) && ausgewaelteObjekte.count != 0 {
                                aktuelleAktion = .drehen
                                dreheAuswahl(um: gesture)
                            }
                        })
                            .onEnded({ _ in
                                initialeDrehungen = nil
                                initialePositionen = nil
                                drehAnkerPunkt = nil
                                if aktuelleAktion == .drehen {
                                    aktuelleAktion = nil
                                }
                            })))
            .onTapGesture {
                ausgewaelteObjekte = []
                ausgehendesElektron = nil
            }.clipped()
        }
    }
    
    var einstellungen: some View {
        NavigationStack {
            Form {
                Section("Einblenden"){
                    Toggle("Oxidationszahlen einblenden", isOn: $oxzahlenEinblenden)
                    Toggle("Keile einblenden", isOn: $keileEinblenden)
                    Toggle("Bindungswinkel einblenden", isOn: $winkelEinblenden)
                }
                Section("Darstellung") {
                    Toggle("Reduzierte Schreibweise", isOn: $reduzierteSchreibweise)
                    if !reduzierteSchreibweise {
                        Picker("Atom-Darstellung", selection: $atomDarstellung) {
                            Text("Kreis mit Hintergrund")
                                .tag("hintergrund")
                            Text("Kreis mit Umrandung")
                                .tag("umrandung")
                            Text("Nur Symbol")
                                .tag("symbol")
                        }
                    }
                    VStack(alignment: .leading, spacing: 20){
                        Text("Hintergrundmuster")
                        HStack(spacing: 20){
                            hintergrundMusterButton("karo")
                            hintergrundMusterButton("liniert")
                        }
                        HStack(spacing: 20){
                            hintergrundMusterButton("punkt_gross")
                            hintergrundMusterButton("punkt_klein")
                        }
                        HStack {
                            Text("Kein Hintergrund")
                        }
                        .frame(width: 320, height: 30)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(hintergrund == "" ? .green : .prim, lineWidth: 1))
                            .onTapGesture {
                                hintergrund = ""
                            }
                    }
                }
                Section("Zoom") {
                    Slider(value: $zoom, in: 0.5...2.0)
                    Text("Aktuell: \(zoom * 100, specifier: "%.0f")%")
                        .font(.caption2)
                }
            }
            .formStyle(.grouped)
            #if os(iOS) || os(visionOS)
            .navigationTitle(UIDevice.current.userInterfaceIdiom == .phone ? "Darstellung" : "")
            #endif
        }
        .frame(minWidth: 400, minHeight: 700)
    }
    
    @MainActor
    var iPadControlls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15){
                Spacer()
                    .frame(height: 0)
                VStack(alignment: .leading, spacing: 8){
                    Text("Hinzufügen")
                    Divider()
                    HStack {
                        Button {
                            if !zeigeEinstellungen {
                                zeigeHinzufuegen = true
                            }
                        } label: {
                            labelButton("Atom hinzufügen", "plus.circle", commands: ["command.square.fill", "n.square.fill"], .indigo)
                        }.keyboardShortcut("n", modifiers: .command)
                            .sheet(isPresented: $zeigeHinzufuegen) {
                                ElementAuswahlListe(hinzufuegen: { element in
                                    withAnimation {
                                        let objekt = CanvasObjekt(element)
                                        canvasObjekte.append(objekt)
                                        ausgewaelteObjekte = [objekt.id]
                                        ausgehendesElektron = nil
                                        letztesAtomSymbol = element.symbol
                                    }
                                }).environment(elemente)
                            }
                            .buttonStyle(.plain)
                        Button {
                            withAnimation {
                                guard let element = elemente.alleElemente.first(where: { $0.symbol == letztesAtomSymbol }) else { return }
                                let objekt = CanvasObjekt(element)
                                canvasObjekte.append(objekt)
                                ausgewaelteObjekte = [objekt.id]
                                ausgehendesElektron = nil
                            }
                        } label: {
                            Text(letztesAtomSymbol)
                                .foregroundStyle(.white)
                                .frame(width: 45, height: 45)
                                .background(.indigo.gradient)
                                .cornerRadius(22.5)
                        }.buttonStyle(.plain)
                    }
                    Button {} label: {
                        VStack(alignment: .leading, spacing: 0){
                            labelButton("Molekül hinzufügen", "plus.circle", commands: ["command.square.fill", "shift.fill", "n.square.fill"], .gray)
                            Text("Bald verfügbar :)")
                                .font(.caption)
                                .padding(4)
                        }
                        .background(.gray.opacity(0.4))
                        .cornerRadius(10)
                        .foregroundStyle(.white)
                    }
                    .disabled(true)
                    .buttonStyle(.plain)
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                }
                VStack(alignment: .leading, spacing: 8){
                    VStack(alignment: .leading, spacing: 4){
                        Text("Werkzeuge")
                        Divider()
                    }.padding(.top)
                    toolButton("hand.point.up.left", .blue, .fingerOderZeiger, "Verschieben")
                    toolButton("app.connected.to.app.below.fill", .cyan, .bindung, "Bindung aufbauen")
                    toolButton("lasso", .green, .lasso, "Lasso")
                    #if os(iOS) || os(visionOS)
                    toolButton("pencil.and.outline", .orange, .zeichnen, "Zeichnen")
                    #endif
                }
                VStack(alignment: .leading, spacing: 8){
                    Text("Aktionen")
                    Divider()
                    Button {
                        loescheElemente()
                    } label: {
                        labelButton("Auswahl löschen", "trash", commands: ["command.square.fill", "delete.left.fill"], ausgewaelteObjekte.isEmpty ? .gray : .red)
                    }
                    .buttonStyle(.plain)
                    .disabled(ausgewaelteObjekte.isEmpty)
                    .keyboardShortcut(.delete)
                    Button {
                        kopieren()
                    } label: {
                        labelButton("Auswahl kopieren", "doc.on.doc", commands: ["command.square.fill", "c.square.fill"], ausgewaelteObjekte.isEmpty ? .gray : .indigo)
                    }
                    .buttonStyle(.plain)
                    .disabled(ausgewaelteObjekte.isEmpty)
                    .keyboardShortcut("c", modifiers: .command)
                    Button {
                        einfuegen()
                    } label: {
                        labelButton("Kopiertes einfügen", "doc.on.clipboard", commands: ["command.square.fill", "v.square.fill"], zwischenSpeicherObjekte.isEmpty ? .gray : .indigo)
                    }
                    .buttonStyle(.plain)
                    .disabled(zwischenSpeicherObjekte.isEmpty)
                    .keyboardShortcut("v", modifiers: .command)
                }
            }
            .padding(.horizontal)
        }
        .frame(width: 350)
    }
    
    #if os(iOS)
    var iPhoneControlls: some View {
        ScrollView([.horizontal]){
            VStack {
                Spacer()
                HStack(alignment: .center, spacing: 10){
                    Button {
                        if !zeigeEinstellungen {
                            zeigeHinzufuegen = true
                        }
                    } label: {
                        Circle()
                            .fill(.green)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "plus")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                    }.sheet(isPresented: $zeigeHinzufuegen) {
                        ElementAuswahlListe(hinzufuegen: { element in
                            withAnimation {
                                let objekt = CanvasObjekt(element)
                                canvasObjekte.append(objekt)
                                ausgewaelteObjekte = [objekt.id]
                                ausgehendesElektron = nil
                                letztesAtomSymbol = element.symbol
                            }
                        }).environment(elemente)
                    }
                    Divider()
                        .background(.prim)
                    toolButton("hand.point.up.left", .blue, .fingerOderZeiger)
                    toolButton("app.connected.to.app.below.fill", .cyan, .bindung)
                    toolButton("lasso", .green, .lasso)
                    toolButton("pencil.and.outline", .orange, .zeichnen)
                    Divider()
                        .background(.prim)
                    Button {
                        loescheElemente()
                    } label: {
                        Circle()
                            .fill(ausgewaelteObjekte.isEmpty ? .gray : .red)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "trash")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                    }.disabled(ausgewaelteObjekte.isEmpty)
                    Button {
                        kopieren()
                    } label: {
                        Circle()
                            .fill(ausgewaelteObjekte.isEmpty ? .gray : .blue)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                    }.disabled(ausgewaelteObjekte.isEmpty)
                    Button {
                        einfuegen()
                    } label: {
                        Circle()
                            .fill(zwischenSpeicherObjekte.isEmpty ? .gray : .blue)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundStyle(.white)
                                    .font(.title3)
                            }
                    }.disabled(zwischenSpeicherObjekte.isEmpty)
                }
                .frame(height: 40)
                .padding(.horizontal, 9)
                Spacer()
            }
        }
        .frame(height: 60)
        .background(.bgr)
    }
    #endif
    
    func HOrVStack(_ content: some View) -> some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return AnyView(VStack(spacing: 0){content})
        } else {
            return AnyView(HStack(spacing: 0){content})
        }
#else
        return HStack(spacing: 0){content}
#endif
    }
    
    private func labelButton(_ titel: String, _ sysImage: String, commands: [String], _ bg: Color) -> some View {
        HStack {
            Image(systemName: sysImage)
            Text(titel)
            Spacer()
            if GCKeyboard.coalesced != nil {
                HStack(spacing: 0){
                    ForEach(commands, id: \.self) { c in Image(systemName: c) }
                }
                .onAppear {
                    print(GCKeyboard.coalesced!.description)
                }
            }
        }.padding()
            .background(bg.gradient)
            .foregroundStyle(.white)
            .cornerRadius(10)
    }
    
    private func toolButton(_ sysImage: String, _ accent: Color, _ state: Werkzeug, _ titel: String? = nil) -> some View {
        Button {
            if ausgewaeltesWerkzeug != state {
                withAnimation {
                    ausgewaeltesWerkzeug = state
                }
            }
        } label: {
            if let titel {
                HStack {
                    if ausgewaeltesWerkzeug == state {
                        accent.frame(width: 7)
                    }
                    HStack {
                        Image(systemName: sysImage)
                        Text(titel)
                    }.padding(10)
                    Spacer()
                }
                .foregroundStyle(ausgewaeltesWerkzeug == state ? accent : .prim)
                .cornerRadius(7.5)
                .frame(height: 41)
                .background(Color.clear.contentShape(Rectangle()))
            } else {
                Circle()
                    .fill(accent)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: sysImage)
                            .foregroundStyle(.white)
                            .font(.title3)
                    }
                    .overlay {
                        if ausgewaeltesWerkzeug == state {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 36, height: 36)
                        }
                    }
            }
        }.buttonStyle(.plain)
    }
    
    private func hintergrundMusterButton(_ muster: String) -> some View {
        Image(muster)
            .renderingMode(.template)
            .resizable(resizingMode: .tile)
            .foregroundStyle(.gray.opacity(0.3))
            .frame(width: 150, height: 75)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(hintergrund == muster ? .green : .prim, lineWidth: 1))
            .onTapGesture {
                hintergrund = muster
            }
    }
    
    private func kopieren(){
        zwischenSpeicherObjekte = []
        zwischenSpeicherBindungen = []
        wieOftEingefuegtOhneNeuZuKopieren = 0
        for i in ausgewaelteObjekte {
            guard let objekt = canvasObjekte.first(where: { $0.id == i }) else { continue }
            zwischenSpeicherObjekte.append(objekt)
            for ii in canvasBindungen {
                if i == ii.erstesCanvasObjekt && ausgewaelteObjekte.contains(ii.zweitesCanvasObjekt) {
                    zwischenSpeicherBindungen.append(ii)
                }
            }
        }
    }
    
    private func einfuegen(){
        //TODO: Fehler beheben, dass Elektronen despawnen wenn sie davor in einer Bindung waren
        var neueIDs = [UUID: UUID]()
        wieOftEingefuegtOhneNeuZuKopieren += 1
        for i in zwischenSpeicherObjekte {
            var neuesObjekt = i
            let neueID = UUID()
            neueIDs[i.id] = neueID
            neuesObjekt.id = neueID
            neuesObjekt.ort = neuesObjekt.ort + CGPoint(x: wieOftEingefuegtOhneNeuZuKopieren * 40, y: wieOftEingefuegtOhneNeuZuKopieren * 40)
            canvasObjekte.append(neuesObjekt)
        }
        for i in zwischenSpeicherBindungen {
            var neueBindung = i
            guard let ersterBindungspartner = neueIDs[i.erstesCanvasObjekt], let zweiterBindungspartner = neueIDs[i.zweitesCanvasObjekt] else { continue }
            neueBindung.id = UUID()
            neueBindung.erstesCanvasObjekt = ersterBindungspartner
            neueBindung.zweitesCanvasObjekt = zweiterBindungspartner
            canvasBindungen.append(neueBindung)
        }
        ausgewaelteObjekte = Array(neueIDs.values)
    }
    
    private func temporaereBindungWegenGezogenemElektron() -> (some View)? {
        
        guard let startPunkt, let aktuellerOrtDesElektrons else { return AnyView?.none }
        
        let vektor = Vektor(vom: startPunkt, zum: aktuellerOrtDesElektrons)
        
        let vektorLaenge = sqrt(pow(vektor.x, 2) + pow(vektor.y, 2))
        
        let winkel = vektor.winkel()
        
        return AnyView(
            ZStack {
                Color
                    .indigo
                    .frame(width: 3, height: vektorLaenge)
                    .frame(width: 20)
                    .overlay(
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.white, .green)
                            .rotationEffect(-winkel)
                            .popover(isPresented: $elektronWurdeZuendeGezogen) {
                                ElementAuswahlGrid(hinzufuegen: { element in
                                    var neuesObjekt = CanvasObjekt(element)
                                    neuesObjekt.ort = aktuellerOrtDesElektrons
                                    canvasObjekte.append(neuesObjekt)
                                    
                                    var freiesElektron = 0
                                    for i in 1...min(neuesObjekt.element.valenzElektronen, 4) {
                                        if !neuesObjekt.valenzelektronen.contains(i+4) {
                                            freiesElektron = i
                                            break
                                        }
                                    }
                                    
                                    if freiesElektron != 0 {
                                        baueBindungAuf(neuesObjekt, vonElektron: freiesElektron)
                                    }
                                    
                                    ausgewaelteObjekte = []
                                    ausgehendesElektron = nil
                                })
                                .environment(elemente)
                                .onDisappear() {
                                    withAnimation{
                                        self.startPunkt = nil
                                        self.aktuellerOrtDesElektrons = nil
                                        self.elektronWurdeZuendeGezogen = false
                                    }
                                }
                            },
                        alignment: .bottom
                    )
                    .cornerRadius(5)
                    .rotationEffect(winkel, anchor: .top)
                    .offset(x: startPunkt.x, y: startPunkt.y + vektorLaenge / 2)
            }
        )
    }
    
    private func bindungAufCanvas(_ bindung: CanvasBindung) -> (some View)? {
        if let ersterIndex = canvasObjekte.firstIndex(where: { objekt in bindung.erstesCanvasObjekt == objekt.id }),
           let zweiterIndex = canvasObjekte.firstIndex(where: { objekt in bindung.zweitesCanvasObjekt == objekt.id }) {
            
            let erstesObjekt = canvasObjekte[ersterIndex]
            let zweitesObjekt = canvasObjekte[zweiterIndex]
            
            let vektor = Vektor(vom: erstesObjekt.ort, zum: zweitesObjekt.ort)
            
            let vektorLaenge = sqrt(pow(vektor.x, 2) + pow(vektor.y, 2))
            let vektorLaengeMitAbstaenden = vektorLaenge - 50
            
            let winkel = vektor.winkel()
            
            return AnyView(
                ZStack {
                    if keileEinblenden && abs((erstesObjekt.element.elektroNegativität ?? 0) - (zweitesObjekt.element.elektroNegativität ?? 0)) >= 0.4 {
                        Dreieck()
                            .fill(.blue)
                            .cornerRadius(5)
                            .frame(width: 24, height: vektorLaengeMitAbstaenden > 0 ? vektorLaengeMitAbstaenden : 0)
                            .rotationEffect((erstesObjekt.element.elektroNegativität ?? 0) > (zweitesObjekt.element.elektroNegativität ?? 0) ? Angle(degrees: 180) : .zero)
                    }
                    HStack (spacing: 2){
                        ForEach(0 ..< bindung.wertigkeit, id: \.self) { _ in
                            VStack(spacing: 0){
                                Color
                                    .primary
                                    .frame(width: 6 - CGFloat(bindung.wertigkeit), height: vektorLaengeMitAbstaenden > 0 ? vektorLaengeMitAbstaenden : 0)
                                    .cornerRadius(5)
                                
                            }
                        }
                    }
                }
                    .rotationEffect(winkel, anchor: .top)
                    .offset(x: erstesObjekt.ort.x + (vektor.x / vektorLaenge)*25, y: erstesObjekt.ort.y + vektorLaengeMitAbstaenden / 2 + (vektor.y / vektorLaenge)*25)
            )
        } else {
            return AnyView?.none // Workaround, da nil als Rückgabe ungültig ist
        }
    }
    
    private func elementAufCanvas(_ objekt: CanvasObjekt) -> some View {
        ZStack {
            Text(objekt.element.symbol)
                .foregroundColor(atomDarstellung == "hintergrund" ? .white : .prim)
                .fontWeight(.bold)
                .frame(width: 35, height: 35)
                .background(atomDarstellung == "hintergrund" ? Color(objekt.element.klassifikation).contentShape(Circle()) : Color.clear.contentShape(Circle()))
                .overlay { atomDarstellung == "umrandung" ? Circle().stroke(.prim, lineWidth: 1).frame(width: 35, height: 35) : nil }
                .cornerRadius(17.5)
                .overlay(ausgewaelteObjekte.contains(objekt.id) && ausgewaeltesWerkzeug != .bindung ? RoundedRectangle(cornerRadius: 17.5).stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [3])) : nil)
                .onTapGesture {
                    #if os(macOS)
                    if NSEvent.modifierFlags.contains(.shift) || ausgewaeltesWerkzeug == .lasso {
                        if let index = ausgewaelteObjekte.firstIndex(of: objekt.id) {
                            ausgewaelteObjekte.remove(at: index)
                        } else {
                            ausgewaelteObjekte.append(objekt.id)
                        }
                    } else {
                        ausgewaelteObjekte = ausgewaelteObjekte.first == objekt.id ? [] : [objekt.id]
                    }
                    #else
                    if ausgewaeltesWerkzeug == .fingerOderZeiger {
                        ausgewaelteObjekte = ausgewaelteObjekte.first == objekt.id ? [] : [objekt.id]
                    } else if ausgewaeltesWerkzeug == .lasso {
                        if let index = ausgewaelteObjekte.firstIndex(of: objekt.id) {
                            ausgewaelteObjekte.remove(at: index)
                        } else {
                            ausgewaelteObjekte.append(objekt.id)
                        }
                    }
                    #endif
                }
                .contextMenu {
                    Group {
                        Button(action: {
                            guard let index = canvasObjekte.firstIndex(of: objekt) else { return }
                            let _ = canvasObjekte[index].ladeNegativ()
                            
                            // Damit kein (zuvor ausgewältes) nicht mehr verfügbares Elektron versucht werden kann zu verbinden
                            ausgehendesElektron = nil
                            ausgewaelteObjekte = []
                        }) {
                            Label("Negativ laden", systemImage: "minus.circle")
                        }
                        Button(action: {
                            guard let index = canvasObjekte.firstIndex(of: objekt) else { return }
                            let _ = canvasObjekte[index].ladePositiv()
                            
                            // Damit kein (zuvor ausgewältes) nicht mehr verfügbares Elektron versucht werden kann zu verbinden
                            ausgehendesElektron = nil
                            ausgewaelteObjekte = []
                        }) {
                            Label("Positiv laden", systemImage: "plus.circle")
                        }
                        Divider()
                        Button {
                            guard let index = canvasObjekte.firstIndex(of: objekt) else { return }
                            withAnimation {
                                canvasObjekte[index].drehung += Angle(degrees: 90)
                            }
                        } label: {
                            Label("Um 90° rechts drehen", systemImage: "arrow.uturn.right.circle")
                        }
                        Button {
                            guard let index = canvasObjekte.firstIndex(of: objekt) else { return }
                            withAnimation {
                                canvasObjekte[index].drehung -= Angle(degrees: 90)
                            }
                        } label: {
                            Label("Um 90° links drehen", systemImage: "arrow.uturn.left.circle")
                        }
                    }
                }
            Group {
                
                let offsets = [
                    1: (0, -25),
                    2: (25, 0),
                    3: (0, 25),
                    4: (-25, 0)
                ]
                
                ForEach(1...4, id: \.self) { i in
                    if !objekt.bestehendeBindungen.contains(i) && objekt.valenzelektronen.contains(i) {
                        
                        let xOffS = offsets[i]!.0
                        let yOffS = offsets[i]!.1
                        
                        if objekt.valenzelektronen.contains(i + 4) || (i == 1 && objekt.valenzelektronen.contains(2) && objekt.element.kernladungszahl - objekt.ladung < 3) {
                            // Balken oben
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 20, height: 5)
                                .rotationEffect(Angle(degrees: xOffS != 0 ? 90 : 0))
                                .offset(x: CGFloat(xOffS), y: CGFloat(yOffS))
                            
                        } else if !(objekt.element.kernladungszahl - objekt.ladung < 3 && i == 2) {
                            // Punkt oben
                            let scale = ausgewaeltesWerkzeug == .bindung ? 1.28 : 1.0
                            
                            punkt(objekt.id, i)
                                .offset(x: CGFloat(scale * Double(xOffS)), y: CGFloat(scale * Double(yOffS)))
                                .onTapGesture {
                                    baueBindungAuf(objekt, vonElektron: i)
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged(){ value in
                                            if ausgewaeltesWerkzeug == .bindung && (aktuelleAktion == nil || aktuelleAktion == .verbindetElektron) {
                                                aktuelleAktion = .verbindetElektron
                                                if startPunkt == nil {
                                                    ausgewaelteObjekte = [objekt.id]
                                                    ausgehendesElektron = i
                                                    
                                                    // Im Verhältnis zum Mittelpunkt der Kugel
                                                    let startPunktLokal = CGPoint(x: Double(xOffS) * 1.3, y: Double(yOffS) * 1.3)
                                                    
                                                    let s = sin(objekt.drehung.radians)
                                                    let c = cos(objekt.drehung.radians)
                                                    
                                                    let xnew: Double = startPunktLokal.x * c - startPunktLokal.y * s
                                                    let ynew: Double = startPunktLokal.x * s + startPunktLokal.y * c
                                                    
                                                    // Im Verhältnis zum Ursprung
                                                    startPunkt = CGPoint(x: xnew, y: ynew) + objekt.ort
                                                }
                                                guard let startPunkt else { return }
                                                
                                                let s = sin(objekt.drehung.radians)
                                                let c = cos(objekt.drehung.radians)
                                                
                                                let xnew: Double = value.translation.width * c - value.translation.height * s
                                                let ynew: Double = value.translation.width * s + value.translation.height * c
                                                
                                                aktuellerOrtDesElektrons = CGPoint(x: startPunkt.x + xnew, y: startPunkt.y + ynew)
                                                
                                                // Finde die Atome, die 56 Pixel um das Aktuell gezogene Elektron herum sind
                                                // Iteriere durch diese Atome, und prüfe ob tatsächlich ein Elektron gemeint sein könnte
                                                // Falls ja setze anderes Elektron auf die ID und die Koordinaten des errechneten Punktes, sonst setzte zurück
                                            }
                                        }
                                        .onEnded({ _ in
                                            if aktuelleAktion == .verbindetElektron {
                                                // Prüfen, ob anderesElektron einen Wert hat. Falls ja, sollen die beiden Elemente miteinander verknüpft werden
                                                elektronWurdeZuendeGezogen = true
                                                aktuelleAktion = nil
                                            }
                                        })
                                )
                        }
                    }
                }
                HStack {
                    if objekt.ladung != 0 {
                        ZStack {
                            Circle()
                                .fill(objekt.ladung > 0 ? .red : .blue)
                            Text(objekt.ladung.formatiertAlsLadung)
                                .scaledToFill()
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.2)
                                .frame(width: 10, height: 10)
                                .rotationEffect(-objekt.drehung)
                        }.frame(width: 15, height: 15)
                    }
                    if let oxidationZahl = oxidationsZahl(von: objekt), oxzahlenEinblenden {
                        Text(oxidationZahl)
                            .minimumScaleFactor(0.2)
                            .frame(width: 15, height: 15)
                            .background(Circle().fill(.bgr))
                            .rotationEffect(-objekt.drehung)
                    }
                }
                .offset(x: !(oxidationsZahl(von: objekt) != nil && objekt.ladung != 0 && oxzahlenEinblenden) ? 25 : 35, y: -25)
            }
            .rotationEffect(objekt.drehung)
        }
        .frame(width: 65, height: 65)
    }
    
    private func punkt(_ id: UUID, _ nummer: Int) -> some View {
        ZStack {
            if ausgewaeltesWerkzeug == .bindung {
                // Größere Hitbox, sonst funktioniert Touch fast nicht...
                Color.clear
                    .contentShape(Circle())
                    .clipShape(Circle())
                    .frame(width: 30, height: 30)
            }
            ZStack {
                if ausgewaeltesWerkzeug == .bindung {
                    if ausgewaelteObjekte.contains(id) && ausgehendesElektron == nummer {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 12, height: 12)
                        Circle()
                            .stroke(.blue, style: StrokeStyle(lineWidth: 1, dash: [3]))
                            .frame(width: 12, height: 12)
                    }
                }
                Circle()
                    .frame(width: 5, height: 5)
            }.scaleEffect(ausgewaeltesWerkzeug == .bindung ? 1.3 : 1)
        }
    }
    
    private func loescheElemente(){
        for objekt in ausgewaelteObjekte {
            // Alle Verbindungen auflösen, welche mit dem Element gemacht wurden
            var canvasIndex = 0
            for bindung in canvasBindungen {
                // Prüfe, ob das zu löschende Element an der aktuell betrachteten Bindung beteiligt ist
                if bindung.erstesCanvasObjekt == objekt {
                    // Finde den Index des anderen Bindungspartner im Objekte-Array, um es mutieren zu können
                    guard let indexVonAnderemBindungspartner = canvasObjekte.firstIndex(where: { $0.id == bindung.zweitesCanvasObjekt}) else { return }
                    // Gebe die Elektronen dieses Objektes wieder frei
                    for i in bindung.zweiteElPositionen {
                        if let index = canvasObjekte[indexVonAnderemBindungspartner].bestehendeBindungen.firstIndex(of: i) {
                            canvasObjekte[indexVonAnderemBindungspartner].bestehendeBindungen.remove(at: index)
                        }
                    }
                    // Lösche die Bindung
                    canvasBindungen.remove(at: canvasIndex)
                    // Erniedrige den Index um 1, da alle folgenden Bindungen aufrutschen werden, um die gelöschte Bindung zu ersetzen
                    canvasIndex -= 1
                } else if bindung.zweitesCanvasObjekt == objekt {
                    // Das gleiche wie oben erläutert
                    guard let indexVonAnderemBindungspartner = canvasObjekte.firstIndex(where: { $0.id == bindung.erstesCanvasObjekt}) else { return }
                    for i in bindung.ersteElPositionen {
                        if let index = canvasObjekte[indexVonAnderemBindungspartner].bestehendeBindungen.firstIndex(of: i) {
                            canvasObjekte[indexVonAnderemBindungspartner].bestehendeBindungen.remove(at: index)
                        }
                    }
                    canvasBindungen.remove(at: canvasIndex)
                    canvasIndex -= 1
                }
                canvasIndex += 1
            }
            // Objekt löschen
            guard let index = canvasObjekte.firstIndex(where: { x in x.id == objekt}) else { return }
            canvasObjekte.remove(at: index)
        }
        ausgewaelteObjekte = []
    }
    
    private func markiereAlleImAusgewaeltenBereich(){
        // Alle zuvor ausgewälten Objekte nicht mehr auswählen
        ausgewaelteObjekte = []
        // Stelle sicher, dass das die Koordinaten des Lassos definiert sind
        guard let ursprung = ursprungDesLassos, let letzterOrt = aktuellerOrtDerLassos else { return }
        // Prüfe für jedes Objekt, ob es im markierten Bereich liegt
        for i in canvasObjekte {
            let liegtImXBereich = i.ort.x >= min(ursprung.x, letzterOrt.x) && i.ort.x <= max(ursprung.x, letzterOrt.x)
            let liegtImYBereich = i.ort.y >= min(ursprung.y, letzterOrt.y) && i.ort.y <= max(ursprung.y, letzterOrt.y)
            if liegtImXBereich && liegtImYBereich {
                ausgewaelteObjekte.append(i.id)
            }
        }
    }
    
    private func baueBindungAuf(_ objekt: CanvasObjekt, vonElektron elektronNummer: Int){
        // Sicherstellen, dass davor schon ein anderes Objekt ausgewählt war
        guard let schonAusgewaelteId = ausgewaelteObjekte.first, schonAusgewaelteId != objekt.id, let indexVonSchonAusgewaeltesObjekt = canvasObjekte.firstIndex(where: {$0.id == schonAusgewaelteId}), let ausgehendesElektron = ausgehendesElektron else {
            ausgewaelteObjekte = [objekt.id]
            ausgehendesElektron = elektronNummer
            return
        }
        
        // Sicherstellen, dass beide Objekte diese Bindung noch eingehen könnten
        guard objekt.koennteBindungEingehen(elektronNummer) && canvasObjekte[indexVonSchonAusgewaeltesObjekt].koennteBindungEingehen(ausgehendesElektron) else { return }
        
        // Prüfen, ob zwischen den Objekten schon eine Bindung existiert
        if let indexBestehendeBindung = canvasBindungen.firstIndex(where: {
            ($0.erstesCanvasObjekt == schonAusgewaelteId && $0.zweitesCanvasObjekt == objekt.id) || ($0.erstesCanvasObjekt == objekt.id && $0.zweitesCanvasObjekt == schonAusgewaelteId)
        }) {
            do {
                try canvasBindungen[indexBestehendeBindung].erhoeheWertigkeit([(objekt.id, elektronNummer), (schonAusgewaelteId, ausgehendesElektron)])
            } catch {
                // TODO: Nutzer über den Fehler informieren
                print(error)
            }
        } else {
            // Neue Bindung muss erstellt werden
            canvasBindungen.append(CanvasBindung(erstesCanvasObjekt: objekt.id, ersteElPositionen: [elektronNummer], zweitesCanvasObjekt: schonAusgewaelteId, zweiteElPositionen: [ausgehendesElektron], wertigkeit: 1))
        }
        
        // Canvas-Objekte müssen geupdated werden
        guard let indexVonObjekt = canvasObjekte.firstIndex(of: objekt) else { return }
        canvasObjekte[indexVonObjekt].neueBindung(elektronNummer)
        canvasObjekte[indexVonSchonAusgewaeltesObjekt].neueBindung(ausgehendesElektron)
        
        // Nach dem Aufbau der Bindung soll nichts mehr ausgewählt sein
        self.ausgehendesElektron = nil
        self.ausgewaelteObjekte = []
    }
    
    private func oxidationsZahl(von objekt: CanvasObjekt) -> String? {
        // Falls das Atom eine Ladung hat, so wird diese erstmal zur Oxidationszahl
        var ergebnis = objekt.ladung
        // Alle Bindungspartner müssen betrachtet werden
        for i in canvasBindungen.filter({
            $0.erstesCanvasObjekt == objekt.id || $0.zweitesCanvasObjekt == objekt.id
        }) {
            let andereId = i.erstesCanvasObjekt == objekt.id ? i.zweitesCanvasObjekt : i.erstesCanvasObjekt
            guard let anderesObjekt = canvasObjekte.first(where: {
                $0.id == andereId
            }) else { continue }
            // Stelle sicher, dass beide Elemente eine Elektronegativität haben
            guard let objElNeg = objekt.element.elektroNegativität, let aObjElNeg = anderesObjekt.element.elektroNegativität else { continue }
            // Errechne Elektronegativitätsdifferenz
            let elektronegativitaetsDifferenz = objElNeg - aObjElNeg
            // Verändere die Oxidationszahl entsprechend
            if elektronegativitaetsDifferenz >= 0.3 {
                ergebnis -= i.wertigkeit
            } else if elektronegativitaetsDifferenz <= -0.3 {
                ergebnis += i.wertigkeit
            }
        }
        // Gib das Ergebnis als römische Zahl zurück
        return ergebnis.roemisch
    }
    
    private func dreheAuswahl(um winkel: Angle){
        // Auswahl zu Indizes im Canvas-Array umformen
        var betroffeneIndizes = [Int]()
        for i in ausgewaelteObjekte {
            if let index = canvasObjekte.firstIndex(where: { $0.id == i}) {
                betroffeneIndizes.append(index)
            }
        }
        if drehAnkerPunkt == nil {
            // Zentrum der Auswahl (Dreh-Anker) ausrechnen
            var kummulierteXWerte = CGFloat.zero
            var kummulierteYWerte = CGFloat.zero
            for i in betroffeneIndizes {
                kummulierteXWerte += canvasObjekte[i].ort.x
                kummulierteYWerte += canvasObjekte[i].ort.y
            }
            let drehAnkerX = kummulierteXWerte / CGFloat(betroffeneIndizes.count)
            let drehAnkerY = kummulierteYWerte / CGFloat(betroffeneIndizes.count)
            drehAnkerPunkt = CGPoint(x: drehAnkerX, y: drehAnkerY)
        }
        guard let drehAnkerPunkt else { return }
        // Alle Objekte um das Zentrum drehen
        // Rotationen anpassen
        if let initialeDrehungen {
            for i in betroffeneIndizes {
                guard let initialeDrehung = initialeDrehungen[i] else { continue }
                canvasObjekte[i].drehung = initialeDrehung + winkel
            }
        } else {
            initialeDrehungen = [:]
            for i in ausgewaelteObjekte {
                if let index = canvasObjekte.firstIndex(where: { $0.id == i}) {
                    initialeDrehungen![index] = canvasObjekte[index].drehung
                    canvasObjekte[index].drehung += winkel
                }
            }
        }
        // Position anpassen
        // Initiale Positionen speichern
        if initialePositionen == nil {
            initialePositionen = [:]
            for i in ausgewaelteObjekte {
                if let index = canvasObjekte.firstIndex(where: { $0.id == i}) {
                    initialePositionen![index] = canvasObjekte[index].ort
                }
            }
        }
        // Stark inspiriert durch Nils Pipenbrinck: https://stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d
        for i in betroffeneIndizes {
            let s = sin(winkel.radians)
            let c = cos(winkel.radians)
            
            guard let initialePosition = initialePositionen?[i] else { continue }
            var posX = initialePosition.x
            var posY = initialePosition.y
            
            posX -= drehAnkerPunkt.x;
            posY -= drehAnkerPunkt.y;
            
            let xneu = posX * c - posY * s;
            let yneu = posX * s + posY * c;
            
            posX = xneu + drehAnkerPunkt.x;
            posY = yneu + drehAnkerPunkt.y;
            
            canvasObjekte[i].ort = CGPoint(x: posX, y: posY)
        }
    }
    
    private enum Werkzeug {
        case fingerOderZeiger
        case lasso
        case bindung
        case zeichnen
    }
    
    private enum NutzerAktion {
        case drehen
        case vergroessern
        case verschiebtElemente
        case verschiebtCanvasOderLasso
        case verbindetElektron
    }
    
    private struct Dreieck: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            return path
        }
    }
    
    private func raumWinkel(von id: UUID) -> Int? {
        guard let objekt = canvasObjekte.first(where: {$0.id == id}) else { return nil }
        let bindungspartner = canvasBindungen.filter({$0.erstesCanvasObjekt == id || $0.zweitesCanvasObjekt == id}).count
        if bindungspartner < 2 { return nil }
        let freieElektronen = objekt.valenzelektronen.count - objekt.bestehendeBindungen.count
        if bindungspartner == 2 {
            if freieElektronen == 4 {
                // Gewinkelt, wie H2O
                return 105
            } else {
                // Linear, wie CO2
                return 180
            }
        } else if bindungspartner == 3 {
            if freieElektronen == 2 {
                // Pyramidal, wie NH3
                return 107
            } else {
                // Trigonal-Planar, wie HCOOH
                return 120
            }
        } else {
            // Bindungspartner == 4
            // Tetraedisch wie NH4+
            return 109
        }
    }
    
    private func formattieren() {
        
    }
}

#if os(iOS) || os(visionOS)
struct ZeichenFlaeche: UIViewRepresentable {
    let aktiv: Bool
    var zeichenflaeche: PKCanvasView
    var picker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        zeichenflaeche.backgroundColor = .clear
        picker.addObserver(zeichenflaeche)
        return zeichenflaeche
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if aktiv {
            zeichenflaeche.becomeFirstResponder()
        } else {
            zeichenflaeche.resignFirstResponder()
        }
        zeichenflaeche.isUserInteractionEnabled = aktiv
        picker.setVisible(aktiv, forFirstResponder: zeichenflaeche)
    }
}
#endif


// Wichtig: Wenn im Bereich eines anderen Elektron losgelassen wird, muss zu diesem Verbunden werden
// Räumliche Struktur des Moleküls

// Es muss zwei zoom Optionen geben. Einmal, wenn man etwas ausgewält hat, das man das größer oder kleiner macht (jedes Objekt könnte noch einen scale-Faktor haben). Der Andere Zoom faktor ist wenn man nichts ausgewält hat der generelle zoom

//Von https://stackoverflow.com/questions/58526632/swiftui-create-a-single-dashed-line-with-swiftui

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
