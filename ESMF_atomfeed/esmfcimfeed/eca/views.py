from django.http import HttpResponse
from eca.models import ESMFAtomFeed

def show_doc(request, doc):
    return HttpResponse(ESMFAtomFeed().get_object(doc))
