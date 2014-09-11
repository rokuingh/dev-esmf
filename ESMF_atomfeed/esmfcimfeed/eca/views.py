from django.http import HttpResponse
from django.template import *
from django.http import *
from django.shortcuts import *

from eca.models import ESMFAtomFeed

def show_doc(request, doc):
    return HttpResponse(ESMFAtomFeed().objects[doc])
#, mimetype="text/xml"
