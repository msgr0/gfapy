import gfapy

class FieldArray(list):
  """
  Array representing multiple values of the same tag in different header lines.
  """
  @property
  def datatype(self):
    return self._datatype

  def __init__(self, datatype, data = []):
    """
    Parameters
    ----------
    datatype : gfapy.field.TAG_DATATYPE
    	The datatype to use.
    """
    self._datatype = datatype
    super().__init__(data)

  def validate(self, fieldname = None):
    """
    Run the datatype-specific validation on each element of the array.

    Parameters
    ----------
    fieldname : str
    	Fieldname to use for error messages.
    """
    validate_gfa_field(None, fieldname)

  def validate_gfa_field(self, datatype, fieldname=None):
    """
    Run a datatype-specific validation on each element of the array,
    using the specified datatype.

    Parameters
    ----------
    datatype : gfapy.field.TAG_DATATYPE or None
     	Datatype to use for the validation. 
      Use None to use the stored datatype (self.datatype)
    fieldname : str
    	Fieldname to use for error messages.
    """
    if not datatype: datatype = self.datatype
    for elem in self:
      gfapy.field.validate_gfa_field(elem, datatype, fieldname)

  def default_gfa_tag_datatype(self):
    """
    Default GFA tag datatype.

    Returns
    -------
    gfapy.Field::TAG_DATATYPE
    """
    return self.datatype

  def to_gfa_field(self, datatype = None, fieldname = None):
    """
    String representation of the field array.
    
    Parameters
    ----------
    datatype : gfapy.field.TAG_DATATYPE
    	*(defaults to: ***self.datatype***)* datatype of the data
    fieldname : str
    	*(defaults to ***None***)* fieldname to use for error messages
    
    Returns
    -------
    str
    	Tab-separated string representations of the elements.
    """
    if datatype == None: datatype = self.datatype
    return "\t".join(
        [ gfapy.field.to_gfa_field(x, datatype, fieldname = fieldname) for x in self])

  def to_gfa_tag(fieldname, datatype = None):
    """
    String representation of the field array as GFA tags.
    
    Parameters
    ----------
    datatype : gfapy.field.TAG_DATATYPE
      *(defaults to: ***self.datatype***)* datatype of the data
    fieldname : str
    	Name of the tag
    
    Returns
    -------
    str
    	Tab-separated GFA tag representations of the elements.
    """
    if datatype == None: datatype = self.datatype
    return "\t".join(
        [ gfapy.field.to_gfa_tag(x, fieldname, datatype) for x in self])

  def vpush(self, value, datatype, fieldname=None):
    """
    Add a value to the array and validate.

    Raises
    ------
    gfapy.InconsistencyError
    	If the type of the new value does not correspond to the type of
      existing values.

    Parameters
    ----------
    value : Object
    	The value to add.
    datatype : gfapy.Field.TAG_DATATYPE or None
    	The datatype to use.
      If not **None**, it will be checked that the specified datatype is the
      same as for previous elements of the field array.
      If **None**, the value will be validated, according to the datatype
      specified on field array creation.
    fieldname : str
    	The field name to use for error messages.
    """
    if datatype is None:
      gfapy.field.validate_gfa_field(value, self.datatype, fieldname)
    elif datatype != self.datatype:
      raise gfapy.InconsistencyError(
        "Datadatatype mismatch error for field {}:\n".format(fieldname)+
        "value: {}\n".format(value)+
        "existing datatype: {};\n".format(self.datatype)+
        "new datatype: {}".format(datatype))
    self.append(value)

  def from_list(self, datatype = None):
    """
    Create a gfapy.FieldArray from a list.

    Parameters
    ----------
    datatype : gfapy.field.TAG_DATATYPE
    """
    if isinstance(self, gfapy.FieldArray):
      return self
    elif datatype is None:
      raise gfapy.ArgumentError("No datatype specified")
    else:
      gfapy.FieldArray(datatype, self)