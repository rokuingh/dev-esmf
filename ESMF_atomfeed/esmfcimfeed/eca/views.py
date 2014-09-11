from django.http import HttpResponse

from eca.models import ESMFCIMDocumentList

def index(request):
    doc_list = ESMFCIMDocumentList.objects
    output = ', '.join([p.title for p in doc_list])
    return HttpResponse(output)

def show_doc(request, doc):
    return HttpResponse(ESMFCIMDocumentList[doc])
