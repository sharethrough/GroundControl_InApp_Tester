//
//  HTMLInputView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-11-04.
//

//
//  HTMLInputView.swift
//  GroundControlTester
//
//  Created by Shuhao Zhang on 2025-10-21.
//

import SwiftUI

/// This is the navigation value. We wrap the string in a struct
/// so the NavigationStack can identify it as a unique destination type.
struct HTMLPayload: Hashable {
    let htmlString: String
}

struct HTMLInputView: View {
    @Binding var path: NavigationPath
    
    @State private var htmlString: String = """
    <style>
        body {
            font-family: -apple-system, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 90vh;
            background-color: #f0f0f0;
            color: #333;
            text-align: center;
        }
        h1 {
            font-size: 24px;
            font-weight: 600;
        }
        p {
            font-size: 16px;
        }
    </style>
    <div>
        <h1>✅ HTML String Loaded</h1>
        <p>Paste your content into the text editor.</p>
    </div>
    """
    
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 1. The Text Editor
            TextEditor(text: $htmlString)
                .focused($isEditorFocused)
                .font(.body.monospaced())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(8)
                .border(Color(UIColor.separator), width: 1)
                .padding()

            // 2. The Load Button
            // We use NavigationLink(value:) to push the HTMLPayload
            // to the NavigationStack, which will be caught by our
            // new .navigationDestination in ContentView.
            NavigationLink(value: HTMLPayload(htmlString: htmlString)) {
                Text("Load HTML")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Load Custom HTML")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditorFocused ? "Done" : "Edit") {
                    isEditorFocused.toggle()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HTMLInputView(path: .constant(NavigationPath()))
    }
}
