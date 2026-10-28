# Removes everything from a JPEG but the picture: EXIF (GPS, camera, time),
# XMP, comments. Pure Ruby, no image library: walks the file's segments and
# drops APP1–APP15 and COM. Returns nil for anything that isn't a JPEG.
module Jpeg
  SOI = "\xFF\xD8".b.freeze
  DROP = ((0xE1..0xEF).to_a + [ 0xFE ]).freeze # APP1–APP15, COM

  def self.strip(data)
    data = data.b
    return nil unless data.start_with?(SOI)

    out = SOI.dup
    pos = 2
    while pos + 4 <= data.bytesize
      return nil unless data.getbyte(pos) == 0xFF

      marker = data.getbyte(pos + 1)
      return out << data.byteslice(pos..) if marker == 0xDA # start of scan: the picture itself, to the end

      length = data.byteslice(pos + 2, 2).unpack1("n")
      return nil if length < 2 || pos + 2 + length > data.bytesize

      out << data.byteslice(pos, 2 + length) unless DROP.include?(marker)
      pos += 2 + length
    end
    nil
  end
end
