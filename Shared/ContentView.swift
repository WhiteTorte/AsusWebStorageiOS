import SwiftUI

struct ContentView: View {
    @State private var v = ""
    @State private var foid = ""
    @State private var ow = ""
    @State private var result = "결과가 여기에 표시됩니다."
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 12) {
            TextField("v value", text: $v)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("foid value", text: $foid)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("ow value", text: $ow)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Send Request") {
                sendRequest()
            }
            .disabled(isLoading)
            ScrollView {
                Text(result)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            Spacer()
        }
        .padding()
    }

    func sendRequest() {
        isLoading = true
        let urlString = "https://www.asuswebstorage.com/navigate/folderbrowse"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postString = "foid=\(foid)&sb=1&sd=0&pa=\(foid)&pn=1&ow=\(ow)"
        request.httpBody = postString.data(using: .utf8)
        request.setValue("Mozilla/5.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue(urlString, forHTTPHeaderField: "Referer")
        request.setValue("v=\(v);", forHTTPHeaderField: "Cookie")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    result = "오류: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    result = "데이터 없음"
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let fileList = (json["FileList"] as? [[String: Any]]) ?? []
                        let folderList = (json["FolderList"] as? [[String: Any]]) ?? []
                        var output = "📂 FolderList:\n"
                        for folder in folderList {
                            let name = folder["rawfoldername"] as? String ?? ""
                            let id = folder["id"] as? String ?? ""
                            let created = folder["createdtime"] as? String ?? ""
                            output += "Folder name: \(name) | ID: \(id) | Created Time: \(created)\n"
                        }
                        output += "\n📄 FileList:\n"
                        for file in fileList {
                            let name = file["rawfilename"] as? String ?? ""
                            let mtime = file["formatedLastModifyTime"] as? String ?? ""
                            output += "File name: \(name) | Last ModifyTime: \(mtime)\n"
                        }
                        result = output
                    } else {
                        let txt = String(data: data, encoding: .utf8) ?? "(텍스트 변환 실패)"
                        result = "JSON 파싱 실패:\n\(txt)"
                    }
                } catch {
                    let txt = String(data: data, encoding: .utf8) ?? "(텍스트 변환 실패)"
                    result = "예외 발생:\n\(txt)"
                }
            }
        }.resume()
    }
}
