## Generic RGBA image buffer.

import aglet/pixeltypes
import aglet/rect
import stb_image/read as stbi

import ../math as rmath

type
  Image* {.byref.} = object
    width*, height*: int32
    data*: seq[uint8]

proc `[]`*(image: Image, position: Vec2i): Rgba8 {.inline.} =
  ## Returns the pixel at the given position.

  let
    redIndex = (position.x + position.y * image.width) * 4
    greenIndex = redIndex + 1
    blueIndex = greenIndex + 1
    alphaIndex = blueIndex + 1
  result = rgba8(
    image.data[redIndex],
    image.data[greenIndex],
    image.data[blueIndex],
    image.data[alphaIndex],
  )

proc `[]`*(image: Image, x, y: int32): Rgba8 {.inline.} =
  ## Shortcut for querying a pixel with a vector.
  image[vec2i(x, y)]

proc debugRepr*(image: Image): string =
  ## Returns a string containing the image represented in ASCII. For debugging
  ## purposes only.

  for y in 0..<image.height:
    if y > 0: result.add('\n')
    for x in 0..<image.width:
      const Intensities = " .:=+*#"
      let
        pixel = image[x, y]
        intensity = (pixel.r.int / 255 +
                     pixel.g.int / 255 +
                     pixel.b.int / 255) / 3 *
                    (pixel.a.int / 255)
      result.add(Intensities[int(intensity * Intensities.len.float)])

proc `[]=`*(image: var Image, position: Vec2i, pixel: Rgba8) {.inline.} =
  ## Sets the pixel at the given position.

  let
    redIndex = (position.x + position.y * image.width) * 4
    greenIndex = redIndex + 1
    blueIndex = greenIndex + 1
    alphaIndex = blueIndex + 1
  image.data[redIndex] = pixel.r
  image.data[greenIndex] = pixel.g
  image.data[blueIndex] = pixel.b
  image.data[alphaIndex] = pixel.a

proc `[]=`*(image: var Image, x, y: int32, pixel: Rgba8) {.inline.} =
  ## Shortcut for setting a pixel with a vector.

  image[vec2i(x, y)] = pixel

proc `[]`*(image: Image, rect: Recti): Image =
  ## Copies a subsection of the given image and returns it.

  assert rect.x >= 0 and rect.y >= 0, "rect coordinates must be inbounds"
  assert rect.x + rect.width <= image.width and
         rect.y + rect.height <= image.height,
         "rect must not extend beyond the image's size"

  result.width = rect.width
  result.height = rect.height
  result.data.setLen(rect.width * rect.height * 4)
  for y in rect.top..<rect.bottom:
    for x in rect.left..<rect.right:
      let resultPosition = vec2i(x - rect.x, y - rect.y)
      result[resultPosition] = image[x, y]

proc init*(image: var Image, size: Vec2i) =
  ## Initializes an empty image buffer.

  image.width = size.x
  image.height = size.y
  image.data.setLen(image.width * image.height * 4)

proc read*(image: var Image, data: string) =
  ## Reads an image from the given string containing a pre-loaded image file.
  ## Supported formats: JPEG, PNG, TGA, BMP, PSD, GIF, PNM.

  var width, height, channels: int
  # i don't like this cast ↓
  image.data =
    stbi.loadFromMemory(cast[seq[byte]](data), width, height, channels, 4)

proc load*(image: var Image, filename: string) {.inline.} =
  ## Loads an image from the given path.
  image.read(readFile(filename))

proc initImage*(size: Vec2i): Image {.inline.} =
  ## Creates and initializes an empty image buffer.
  result.init(size)

proc readImage*(data: string): Image {.inline.} =
  ## Creates and reads an image from the given string containing an
  ## in-memory image file.
  result.read(data)

proc loadImage*(filename: string): Image {.inline.} =
  ## Creates and loads an image from the given path.
  result.load(filename)
