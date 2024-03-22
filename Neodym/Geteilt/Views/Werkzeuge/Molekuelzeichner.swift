//
//  Molekuelzeichner.swift
//  Neodym
//
//  Created by Max Eckstein on 06.06.23.
//

import SwiftUI
import PencilKit

struct Molekuelzeichner: View {
    
    // Elemente
    @Environment(Elemente.self) private var elemente
    
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
    
    @State private var canvasView = PKCanvasView()
    
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
    // Standartwerte sind, falls keys noch nicht vorhanden sind: Wasserstoff und Lewisschreibweise eingeblendet, zoom = 1.0
    // Die Keys mussten teilweise negativiert werden, damit die Standartwerte passen
    @State var wasserstoffEinblenden = !UserDefaults.standard.bool(forKey: "wasserstoffAusblenden")
    @State var oxidationszahlenEinblenden = !UserDefaults.standard.bool(forKey: "oxidationszahlenAusblenden")
    @State var zoom = UserDefaults.standard.double(forKey: "zoom")
    @State var letzterZoom = 1.0
    
    @State private var aktuelleAktion: NutzerAktion? = nil

    private let canvasGroesse: CGFloat = UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.width * 3 : UIScreen.main.bounds.height * 3
    
    var body: some View {
        GeometryReader { geo in
            ZStack (alignment: .topLeading) {
                
                // Canvas
                ZStack(alignment: .center) {
                    ZStack (alignment: .center) {
                        
                        // Hintergrund
                        Color
                            .gray
                            .opacity(0.2)
                                                
                        // Kreuz im Hintergrund
                        ZStack (alignment: .center){
                            Line()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [10]))
                                .fill(Color.pink)
                                .frame(height: 1)
                            Line()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [10]))
                                .fill(Color.pink)
                                .frame(height: 1)
                                .rotationEffect(Angle(degrees: 90))
                        }
                        .frame(width: 70, height: 70)
                        
                        // Optional das gezeichnete
                        if ausgewaeltesWerkzeug != .zeichnen {
                            InaktiveZeichenFlaeche(canvasView: $canvasView)
                                .frame(width: canvasGroesse, height: canvasGroesse)
                        }
                        
                        // Bei Lasso der ausgewählte Bereich
                        if ausgewaeltesWerkzeug == .lasso && ursprungDesLassos != nil && aktuellerOrtDerLassos != nil {
                            let breite = ursprungDesLassos!.x - aktuellerOrtDerLassos!.x
                            let hoehe = ursprungDesLassos!.y - aktuellerOrtDerLassos!.y
                            Color
                                .blue
                                .opacity(0.3)
                                .cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(lineWidth: 1))
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
                            if !(!wasserstoffEinblenden && objekt.element.symbol == "H"){
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
                        
                    }
                    .frame(width: canvasGroesse, height: canvasGroesse)
                    if ausgewaeltesWerkzeug == .zeichnen {
                        ZeichenFlaeche(canvasView: $canvasView)
                            .frame(width: canvasGroesse, height: canvasGroesse)
                    }
                    
                }
                .position(x: geo.size.width / 2, y: (geo.size.height - 50) / 2)
                // Verschiebung des Canvas
                .offset(ortDesCanvas)
                .frame(height: abs(geo.size.height - 50)) // abs()-Funktion, da sonst der Compiler rumheult
                .scaleEffect(zoom)
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
                                        let y = (value.location.y - (geo.size.height - 50) / 2) / zoom - ortDesCanvas.height
                                        
                                        aktuellerOrtDerLassos = CGPointMake(x, y)
                                        
                                        // Falls der Ursprung noch nicht definiert ist, soll er definiert werden als die aktuelle Position
                                        if ursprungDesLassos == nil {
                                            ursprungDesLassos = CGPointMake(x, y)
                                        }
                                    } else {
                                        // Sonst soll der Canvas verschoben werden
                                        let x = ortDesCanvas.width + (value.translation.width - aktuelleVerschiebung.width) / zoom
                                        let y = ortDesCanvas.height + (value.translation.height - aktuelleVerschiebung.height) / zoom
                                        if abs(x) + geo.size.width / 2 < canvasGroesse / 2 {
                                            ortDesCanvas.width = x
                                        }
                                        if abs(y) + (geo.size.height - 50) / 2 < canvasGroesse / 2 {
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
                        }
                    }
                    .onEnded({ _ in
                        if aktuelleAktion == .vergroessern {
                            letzterZoom = 1.0
                            aktuelleAktion = nil
                            UserDefaults.standard.setValue(zoom, forKey: "zoom")
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
                }
                .cornerRadius(10)
                .padding(.top, 50)
                // Buttons für zusätzliche Funktionen
                HStack (spacing: 10){
                    Button {
                        if !zeigeEinstellungen {
                            zeigeHinzufuegen = true
                        }
                    } label: {
                        ZStack{
                            Circle()
                                .fill(.white)
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.green)
                        }
                    }.sheet(isPresented: $zeigeHinzufuegen) {
                        ElementAuswahlListe(hinzufuegen: { element in
                            withAnimation {
                                canvasObjekte.append(CanvasObjekt(element))
                                ausgewaelteObjekte = []
                                ausgehendesElektron = nil
                            }
                        }).environment(elemente)
                    }
                    Button {
                        loescheElemente()
                    } label: {
                        ZStack{
                            Circle()
                                .fill(.white)
                            Image(systemName: "trash.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(ausgewaelteObjekte.first == nil ? .gray : .red)
                        }
                    }.disabled(ausgewaelteObjekte.first == nil)
                        .keyboardShortcut(.delete)
                    Divider()
                    Button {
                        withAnimation {
                            ausgewaeltesWerkzeug = .fingerOderZeiger
                            ausgewaelteObjekte = []
                            ausgehendesElektron = nil
                        }
                    } label: {
                        Image(systemName: "hand.point.up.left")
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Circle().fill(.cyan))
                            .overlay(ausgewaeltesWerkzeug == .fingerOderZeiger ? Circle().stroke(lineWidth: 2).foregroundColor(Color(UIColor.systemBackground)).frame(width: 34, height: 34) : nil)
                    }
                    Button {
                        withAnimation {
                            ausgewaeltesWerkzeug = .bindung
                            ausgewaelteObjekte = []
                        }
                    } label: {
                        Image(systemName: "app.connected.to.app.below.fill")
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Circle().fill(.cyan))
                            .overlay(ausgewaeltesWerkzeug == .bindung ? Circle().stroke(lineWidth: 2).foregroundColor(Color(UIColor.systemBackground)).frame(width: 34, height: 34) : nil)
                    }
                    Button {
                        withAnimation {
                            ausgewaeltesWerkzeug = .lasso
                            ausgewaelteObjekte = []
                            ausgehendesElektron = nil
                        }
                    } label: {
                        Image(systemName: "lasso")
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Circle().fill(.blue))
                            .overlay(ausgewaeltesWerkzeug == .lasso ? Circle().stroke(lineWidth: 2).foregroundColor(Color(UIColor.systemBackground)).frame(width: 34, height: 34) : nil)
                    }
                    Button {
                        withAnimation {
                            ausgewaeltesWerkzeug = .zeichnen
                            ausgewaelteObjekte = []
                            ausgehendesElektron = nil
                        }
                    } label: {
                        Image(systemName: "pencil.line")
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Circle().fill(.orange))
                            .overlay(ausgewaeltesWerkzeug == .zeichnen ? Circle().stroke(lineWidth: 2).foregroundColor(Color(UIColor.systemBackground)).frame(width: 34, height: 34) : nil)
                    }
                    if geo.size.width > 500 {
                        Divider()
                        Button {
                            kopieren()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .background(Circle().fill(ausgewaelteObjekte.isEmpty ? .gray : .pink))
                        }.disabled(ausgewaelteObjekte.isEmpty)
                            .keyboardShortcut("c", modifiers: .command)
                        Button {
                            einfuegen()
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .background(Circle().fill(zwischenSpeicherObjekte.isEmpty ? .gray : .pink))
                        }.disabled(zwischenSpeicherObjekte.isEmpty)
                            .keyboardShortcut("v", modifiers: .command)
                    }
                }
                .frame(height: 40)
            }
        }
        .padding(.bottom, 10)
        .padding(.horizontal, 20)
        .navigationTitle("Molekülzeichner")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing){
                Button {
                    zeigeEinstellungen = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }.popover(isPresented: $zeigeEinstellungen) {
                    NavigationStack {
                        Form {
                            Section("Ausblenden"){
                                Toggle("Wasserstoffatome einblenden", isOn: $wasserstoffEinblenden)
                                    .onChange(of: wasserstoffEinblenden) { _, neuerWert in
                                        UserDefaults.standard.set(!neuerWert, forKey: "wasserstoffAusblenden")
                                    }
                                Toggle("Oxidationszahlen einblenden", isOn: $oxidationszahlenEinblenden)
                                    .onChange(of: oxidationszahlenEinblenden) { _, neuerWert in
                                        UserDefaults.standard.set(!neuerWert, forKey: "oxidationszahlenAusblenden")
                                    }
                            }
                            Section("Anzeige") {
                                VStack (alignment: .leading, spacing: 0){
                                    Slider(value: $zoom, in: 0.5...2.0)
                                    Text("Aktuell: \(zoom * 100, specifier: "%.0f")%")
                                        .font(.caption2)
                                }.onChange(of: zoom) {
                                    UserDefaults.standard.setValue(zoom, forKey: "zoom")
                                }
                            }
                            //Text("Bindungswinkel einblenden")
                        }.navigationTitle(UIDevice.current.userInterfaceIdiom == .phone ? "Darstellung" : "")
                    }.frame(minWidth: 350, minHeight: 275)
                }
            }
        }
        .onAppear {
            if zoom == 0.0 {
                zoom = 1.0
                UserDefaults.standard.setValue(1.0, forKey: "zoom")
            }
        }
        .onDisappear {
            // Reste löschen
            canvasView.drawing = PKDrawing()
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
                                    withAnimation {
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
                                    }
                                })
                                .environment(elemente)
                                .frame(minWidth: 450, minHeight: 350)
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
                .foregroundColor(.white)
                .fontWeight(.bold)
                .frame(width: 35, height: 35)
                .background(Color(objekt.element.klassifikation))
                .cornerRadius(17.5)
                .overlay(ausgewaelteObjekte.contains(objekt.id) && ausgewaeltesWerkzeug != .bindung ? RoundedRectangle(cornerRadius: 17.5).stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [3])) : nil)
                .onTapGesture {
                    switch ausgewaeltesWerkzeug {
                        case .fingerOderZeiger:
                            ausgewaelteObjekte = ausgewaelteObjekte.first == objekt.id ? [] : [objekt.id]
                            
                        case .lasso:
                            if let index = ausgewaelteObjekte.firstIndex(of: objekt.id) {
                                ausgewaelteObjekte.remove(at: index)
                            } else {
                                ausgewaelteObjekte.append(objekt.id)
                            }
                        
                        default:
                            break
                            
                    }
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
                    if let oxidationZahl = oxidationsZahl(von: objekt), oxidationszahlenEinblenden {
                        Text(oxidationZahl)
                            .frame(height: 15)
                            .rotationEffect(-objekt.drehung)
                    }
                }
                .offset(x: !(oxidationsZahl(von: objekt) != nil && objekt.ladung != 0 && oxidationszahlenEinblenden) ? 25 : 35, y: -25)
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
}

struct ZeichenFlaeche: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let picker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        // Auch mit Finger zeichnen ist erlaubt
        canvasView.drawingPolicy = .anyInput
        
        // Zuvor wurde die Interaktion bei der „InaktivenZeichenFlaeche“ eingeschränkt, deshalb müssen sie hier reaktiviert werden
        canvasView.isUserInteractionEnabled = true
        
        // Damit der Toolpicker angezeigt wird
        canvasView.becomeFirstResponder()
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        // Damit der Toolpicker angezeigt wird
        picker.addObserver(canvasView)
        picker.setVisible(true, forFirstResponder: canvasView)
        DispatchQueue.main.async {
            canvasView.becomeFirstResponder()
        }
    }
}

struct InaktiveZeichenFlaeche: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        // Wird von beiden Zeichenflächen als erste angezeigt, deshalb muss hier die Hintergrundfarbe definiert werden
        canvasView.backgroundColor = .clear
        
        // Damit nicht aus Versehen interagiert werden kann
        canvasView.isUserInteractionEnabled = false
        
        // Damit der Toolpicker nicht mehr angezeigt wird
        canvasView.resignFirstResponder()
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {}
}


// Wichtig: Wenn im Bereich eines anderen Elektron losgelassen wird, muss zu diesem Verbunden werden
// Letztes Element nochmal einfügen (als extra-Button)
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
