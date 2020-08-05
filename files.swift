//
//  files.swift
//

import Foundation


// Global variables
var files = [URL]()
var isCompilingForLocalUse = false
var rootDirectory: String = ""


func initialize(_ path: inout String) -> Bool {
	// Get path from input
	print("Enter directory path: ", terminator: "")
	path = readLine()!
	
	// Check if it is a directory
	let url = URL(fileURLWithPath: path)
	if url.hasDirectoryPath {
		print("Compiling for local use? (y/n) ", terminator: "")
		let answer = readLine()!
		isCompilingForLocalUse = answer.lowercased() == "y" || answer.lowercased() == "yes" ? true : false
		return true
	}
	else { return false }
}


func process(_ path: String, _ isSubdirectory: Bool) {
	var subdirectories = [URL]()
	let url = URL(string: path)!
	let filesInDirectory = try! FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
	
	// Add files to array
	for file in filesInDirectory {
		if file.hasDirectoryPath {
			// It is a subdirectory, make sure it doesn't start with "_"
			if file.lastPathComponent.prefix(1) != "_" { subdirectories.append(file) }
		}
		else {
			// It is a file, make sure it is .html
			let filetype = file.lastPathComponent.split(separator: ".").last!
			if filetype == "html" {
				files.append(file)
			}
		}
	}
	
	// Convert files in subdirectories
	for sub in subdirectories {
		process(String(sub.absoluteString.dropLast()), true)
	}

	// Convert each file
	if !isSubdirectory {
		for file in files {
			let content = parse(file)
			let directory = file.absoluteString.replacingOccurrences(of: "file://" + rootDirectory, with: "").replacingOccurrences(of: file.lastPathComponent, with: "")
			print("Creating: " + directory + file.lastPathComponent)
			let filePath = rootDirectory + "/_public" + directory + file.lastPathComponent
			if directory != "/" {
				// Check if subdirectory exists, if not create it
				let directoryURL = URL(fileURLWithPath: filePath.replacingOccurrences(of: "/" + file.lastPathComponent, with: ""))
				if !directoryURL.hasDirectoryPath {
					try! FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
				}
			}
			try! content.write(toFile: filePath, atomically: true, encoding: .utf8)
		}
		print("Complete!")
	}
}


func parse(_ file: URL) -> String {
	let content = try! String(contentsOf: file)
	let settings = try! String(contentsOf: URL(fileURLWithPath: rootDirectory + "/settings.json"))
	let data = content.components(separatedBy: "<x-data/>\n")
	
	// Get website settings
	var json = try! JSONSerialization.jsonObject(with: settings.data(using: .utf8)!, options: .mutableContainers) as? [String: Any]
	let websiteName = json!["name"] as? String ?? ""
	let websiteURL = isCompilingForLocalUse ? json!["url-local"] as? String ?? "" : json!["url"] as? String ?? ""
	
	// Get page data
	json = try! JSONSerialization.jsonObject(with: data[0].data(using: .utf8)!, options: .mutableContainers) as? [String: Any]
	let pageTitle = json!["title"] as? String ?? ""
	let pageDescription = json!["description"] as? String ?? ""
	let pageLayout = json!["layout"] as? String ?? ""
	
	// Compile page
	var page = try! String(contentsOf: URL(fileURLWithPath: rootDirectory + "/_layouts/" + pageLayout + ".html"))
	page = page.replacingOccurrences(of: "{{ page.content }}", with: data[1])
	let codeblocks = matches(for: "<codeblock>(.|\n)*?</codeblock>", in: page)
	for block in codeblocks {
		page = page.replacingOccurrences(of: block, with: codeblock(block))
	}
	page = page.replacingOccurrences(of: "{{ page.title }}", with: pageTitle)
	page = page.replacingOccurrences(of: "{{ page.description }}", with: pageDescription)
	page = page.replacingOccurrences(of: "{{ site.name }}", with: websiteName)
	page = page.replacingOccurrences(of: "{{ site.url }}", with: websiteURL)
	
	return page
}


func codeblock(_ code: String) -> String {
	var code = code.replacingOccurrences(of: "<codeblock>", with: "%_cb%").replacingOccurrences(of: "</codeblock>", with: "%/_cb%")
	code = code.replacingOccurrences(of: "<", with: "&lt;")
	code = code.replacingOccurrences(of: ">", with: "&gt;")
	code = code.replacingOccurrences(of: "{", with: "&#123;")
	code = code.replacingOccurrences(of: "}", with: "&#125;")
	code = code.replacingOccurrences(of: "  ", with: "&emsp;&emsp;")
	code = code.replacingOccurrences(of: "\n", with: "<br/>")
	code = code.replacingOccurrences(of: "%_cb%", with: "<codeblock>").replacingOccurrences(of: "%/_cb%", with: "</codeblock>")
	return code;
}


func matches(for regex: String, in text: String) -> [String] {
	let regex = try! NSRegularExpression(pattern: regex)
	let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
	return results.map {
		String(text[Range($0.range, in: text)!])
	}
}
