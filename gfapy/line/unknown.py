from .line import Line

class Unknown(Line):
  """
  A GFA2 line which was referred to only by G or O lines
  and has not been found yet (ie is always virtual)
  """

  RECORD_TYPE = None
  POSFIELDS = ["name"]
  FIELD_ALIAS = { }
  PREDEFINED_TAGS = []
  DATATYPE = {
      "name" : "identifier_gfa2",
  }
  REFERENCE_FIELDS = []
  NAME_FIELD = "name"
  STORAGE_KEY = "name"
  REFERENCE_RELATED_FIELDS = []
  DEPENDENT_LINES = ["sets", "paths"]
  OTHER_REFERENCES = []

  def __str__(self):
    return "?record_type?\t{}\tco:Z:line_created_by_RGFA".format(self.name)

  def is_virtual(self):
    return True

Unknown._Line__define_field_methods()
