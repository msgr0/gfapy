import gfapy
from ..line import Line
from .init import Init
from .tags import Tags
from .writer import Writer

class Comment(Writer, Tags, Init, Line):
  """
  A comment line of a GFA file

  The content of the comment line, excluding the initial **#** and eventual
  initial spacing characters, is included in the field **content**.

  The initial spacing characters can be read/changed using the **spacer**
  field. The default value is a single space.

  Tags are not supported by comment lines. If the line contains tags,
  these are nor parsed, but included in the **content** field.
  Trying to set or get tag values raises exceptions.
  """

#TODO: translate examples
#  @example Direct instantiation
#  l = RGFA::Line::Comment.new(["hallo"])
#  l.to_s # => "# hallo"
#  # second field is the spacer (default: single space)
#  l = RGFA::Line::Comment.new(["hallo", "\t"])
#  l.to_s # => "#\thallo"
#
#  @example Validation
#  # Content shall not contain newlines:
#  RGFA::Line::Comment.new(["hallo\nhallo"]) # raises RGFA::FormatError
#  # Spacer shall not contain newlines:
#  RGFA::Line::Comment.new(["hallo", "\n"]) # raises RGFA::FormatError
#  # Validations can be turned off:
#  RGFA::Line::Comment.new(["hallo", "\n"], validate: 0) # nothing raised
#  # No validations on content setting by default
#  l = RGFA::Line::Comment.new(["hallo"])
#  l.content = "hallo\n" # nothing raised
#  l.to_s # raises RGFA::FormatError
#  # Validations on content setting can be turned on
#  l = RGFA::Line::Comment.new(["hallo"], validate: 3)
#  l.content = "hallo\n" # raises RGFA::FormatError
#
#  @example Non-spacing characters in spacer
#  l = RGFA::Line::Comment.new(["hallo", ": "])
#  # non-spacing chars will not be recognized
#  # when converting the string representation back to a Line object
#  l.to_s.to_rgfa_line.content # => ": hallo"
#  # however, it works when converting back from array representation
#  l.to_a.to_rgfa_line.content # => "hallo"
#  # or if the spacer does not contain non-spacing chars
#  l.spacer = " "
#  l.to_s.to_rgfa_line.content # => "hallo"
#
#  @example From string
#  l = "# hallo".to_rgfa_line
#  l.content # => "hallo"
#  l.spacer # => " "
#  # initializing from string, only spacing characters are recognized as spacer
#  l = "#: hallo".to_rgfa_line
#  l.content # => ": hallo"
#  l.spacer # => ""
#
#  @example To string
#  l = "# hallo".to_rgfa_line
#  l.to_s # => "# hallo"
#  l.spacer = ""
#  l.to_s # => "#hallo"
#  l = "# hallo".to_rgfa_line(validate: 3)
#  l.spacer = "\n" # raises RGFA::FormatError as validation >= 3
#
#  @example Comment lines have no tags
#  RGFA::Line::Comment.new(["hallo", " ", "zz:Z:hallo"])
#  # => raises RGFA::ValueError
#  l = "# hallo zz:Z:hallo".to_rgfa_line
#  l.content # => "hallo zz:Z:hallo"
#  l.zz # => raises NoMethodError
#  l.zz = 1 # raises NoMethodError
#  l.set(:zz, 1) # raises RGFA::RuntimeError
#  l.get(:zz) # returns nil

  RECORD_TYPE = "#"
  POSFIELDS = ["content", "spacer"]
  PREDEFINED_TAGS = []
  DATATYPE = {
    "content" : "comment",
    "spacer" : "comment",
  }
  FIELD_ALIAS = {}
  REFERENCE_FIELDS = []
  REFERENCE_RELATED_FIELDS = []
  DEPENDENT_LINES = []
  OTHER_REFERENCES = []

Comment._Line__define_field_methods()