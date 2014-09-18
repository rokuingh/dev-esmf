from django.http import HttpResponse
from eca.models import ESMFAtomFeed

def show_doc(request, doc):
    docstring = next((x.xmlstring for x in ESMFAtomFeed().cimfiles if x.title == doc), None)
    return HttpResponse(docstring, content_type='text/xml')
