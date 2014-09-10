from django.http import HttpResponse

from feed.models import ESMFCIMDocument

def index(request):
    doc_list = ESMFCIMDocument.objects.order_by('-pub_date')[:5]
    output = ', '.join([p.title for p in doc_list])
    return HttpResponse(output)

def show_doc(request, document_id):
    return HttpResponse('/Users/ryan.okuinghttons/sandbox/esmf_dev/atomfeed3/data/'+str(document_id))
