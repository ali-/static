//
//  main.swift
//

import Foundation


// Loop until we get a valid directory
while(true) {
	if initialize(&rootDirectory) { break }
}


// Remove files in /_public/
while (true) {
	let filesInDirectory = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: rootDirectory + "/_public"), includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
	for file in (filesInDirectory ?? []) {
		do {
			try? FileManager.default.removeItem(at: file)
		}
		catch {
			print("The file \(file.path) could not be opened")
		}
	}
	break
}


// Process main directory
process(rootDirectory, false)
