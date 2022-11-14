# frozen_string_literal: true

# Detect a file's type based on its file signature.
#
# @see https://en.wikipedia.org/wiki/List_of_file_signatures
class FileTypeDetector
  extend Memoist
  attr_reader :file

  # @param [File] The file to detect.
  def initialize(file)
    @file = file
  end

  # @return [Symbol] The file's extension (e.g. :jpg, :png, etc). Returns `:bin` if the file type is unknown.
  memoize def file_ext
    header = file.pread(16, 0)

    case header
    when /\A\xff\xd8/n
      :jpg
    when /\AGIF87a/, /\AGIF89a/
      :gif
    when /\A\x89PNG\r\n\x1a\n/n
      :png
    when /\ACWS/, /\AFWS/, /\AZWS/
      :swf

    # This detects the Matroska (.mkv) header. WebM files have a DocType of "webm", which is checked later in `MediaFile::Video#is_supported?`.
    #
    # https://www.rfc-editor.org/rfc/rfc8794.html#section-8.1
    # https://www.webmproject.org/docs/container/
    when /\A\x1a\x45\xdf\xa3/n
      :webm

    # https://developers.google.com/speed/webp/docs/riff_container
    when /\ARIFF....WEBP/
      :webp

    # https://www.ftyps.com
    # https://cconcolato.github.io/mp4ra/filetype.html
    # https://github.com/mozilla/gecko-dev/blob/master/toolkit/components/mediasniffer/nsMediaSniffer.cpp#L78
    # https://mimesniff.spec.whatwg.org/#signature-for-mp4
    #
    # isom (common) - MP4 Base Media v1 [IS0 14496-12:2003]
    # mp42 (common) - MP4 v2 [ISO 14496-14]
    # iso4 (rare) - MP4 Base Media v4
    # iso5 (rare) - MP4 Base Media v5 (used by Twitter)
    # 3gp5 (rare) - 3GPP Media (.3GP) Release 5 (XXX technically this should be .3gp, not .mp4. Supported by Chrome but not Firefox)
    # avc1 (rare) - MP4 Base w/ AVC ext [ISO 14496-12:2005]
    # M4V (rare) - Apple iTunes Video (https://en.wikipedia.org/wiki/M4V)
    when /\A....ftyp(?:mp4|avc|iso|3gp5|M4V)/
      :mp4

    # https://aomediacodec.github.io/av1-avif/#brands-overview
    when /\A....ftyp(?:avif|avis)/
      :avif
    when /\APK\x03\x04/
      :zip
    else
      :bin
    end
  rescue EOFError
    :bin
  end

  # @return [String] The file's MIME type, or "application/octet-stream" if unknown.
  def mime_type
    Mime::Type.lookup_by_extension(file_ext).to_s.presence || "application/octet-stream"
  end
end
