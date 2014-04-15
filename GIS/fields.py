from django.http import QueryDict
from django.core.exceptions import ValidationError
from rest_framework.fields import WritableField


class ListField(WritableField):

    def __init__(self, field, *args, **kwargs):
        super(ListField, self).__init__(*args, **kwargs)
        self.field = field

    def initialize(self, parent, field_name):
        super(ListField, self).initialize(parent, field_name)
        self.field.initialize(self, field_name)

    def to_native(self, value):
        if value is None:
            return None
        return [self.field.to_native(item) for item in value]

    def from_native(self, value):
        if value is None:
            return None
        result = []
        for item in value:
            result.append(self.field.from_native(item))
        return result

    def field_from_native(self, data, files, field_name, into):
        if isinstance(data, QueryDict) and field_name in data:
            data = {field_name: data.getlist(field_name)}
        if isinstance(files, QueryDict) and field_name in files:
            files = {field_name: files.getlist(field_name)}
        super(ListField, self).field_from_native(data, files, field_name, into)
