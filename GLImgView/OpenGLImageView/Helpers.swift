//
//  Helpers.swift
//  ProgSConCompanion
//
//  Created by Simon Gladman on 19/04/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit
import Accelerate

let bitmapInfo:CGBitmapInfo = CGBitmapInfo(
  rawValue: CGImageAlphaInfo.last.rawValue)

var format = vImage_CGImageFormat(
  bitsPerComponent: 8,
  bitsPerPixel: 32,
  colorSpace: nil,
  bitmapInfo: bitmapInfo,
  version: 0,
  decode: nil,
  renderingIntent: .defaultIntent)

extension UIImage
{
  convenience init?(fromvImageOutBuffer outBuffer:vImage_Buffer)
  {
    var mutableBuffer = outBuffer
    var error = vImage_Error()
    
    let cgImage = vImageCreateCGImageFromBuffer(
      &mutableBuffer,
      &format,
      nil,
      nil,
      UInt32(kvImageNoFlags),
      &error)
    
    self.init(cgImage: (cgImage?.takeRetainedValue())!)
  }
}

