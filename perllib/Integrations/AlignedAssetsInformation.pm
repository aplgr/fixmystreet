package Integrations::AlignedAssetsInformation;
# Generated by SOAP::Lite (v1.27) for Perl -- soaplite.com
# Copyright (C) 2000-2006 Paul Kulchenko, Byrne Reese
# -- generated at [Thu Jun 15 09:43:54 2023]
# -- generated from https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx?WSDL
my %methods = (
'GetAllFields' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/GetAllFields',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'adapterName', type => 's:string', attr => {}),
    ], # end parameters
  }, # end GetAllFields
'GetReturnFields' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/GetReturnFields',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'adapterName', type => 's:string', attr => {}),
    ], # end parameters
  }, # end GetReturnFields
'GetSearchFields' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/GetSearchFields',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'adapterName', type => 's:string', attr => {}),
    ], # end parameters
  }, # end GetSearchFields
'GetAdapters' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/GetAdapters',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
    ], # end parameters
  }, # end GetAdapters
'SearchFieldsSupported' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/SearchFieldsSupported',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'adapterName', type => 's:string', attr => {}),
    ], # end parameters
  }, # end SearchFieldsSupported
'GetResultFields' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/GetResultFields',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'adapterName', type => 's:string', attr => {}),
    ], # end parameters
  }, # end GetResultFields
'GetVersions' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/GetVersions',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
    ], # end parameters
  }, # end GetVersions
'ResultFieldsSupported' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/ResultFieldsSupported',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'adapterName', type => 's:string', attr => {}),
    ], # end parameters
  }, # end ResultFieldsSupported
'CheckApiKey' => {
    endpoint => 'https://webhost.aligned-assets.co.uk/cbeds/webservices/v2/searchserviceinformation.asmx',
    soapaction => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation/CheckApiKey',
    namespace => 'http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation',
    parameters => [
      SOAP::Data->new(name => 'apiKey', type => 's:string', attr => {}),
    ], # end parameters
  }, # end CheckApiKey
); # end my %methods

use SOAP::Lite;
use Exporter;
use Carp ();

use vars qw(@ISA $AUTOLOAD @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter SOAP::Lite);
@EXPORT_OK = (keys %methods);
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);

sub _call {
    my ($self, $method) = (shift, shift);
    my $name = UNIVERSAL::isa($method => 'SOAP::Data') ? $method->name : $method;
    my %method = %{$methods{$name}};
    $self->proxy($method{endpoint} || Carp::croak "No server address (proxy) specified")
        unless $self->proxy;
    my @templates = @{$method{parameters}};
    my @parameters = ();
    foreach my $param (@_) {
        if (@templates) {
            my $template = shift @templates;
            my ($prefix,$typename) = SOAP::Utils::splitqname($template->type);
            my $method = 'as_'.$typename;
            # TODO - if can('as_'.$typename) {...}
            my $result = $self->serializer->$method($param, $template->name, $template->type, $template->attr);
            push(@parameters, $template->value($result->[2]));
        }
        else {
            push(@parameters, $param);
        }
    }
    $self->endpoint($method{endpoint})
       ->ns($method{namespace})
       ->on_action(sub{qq!"$method{soapaction}"!});
  $self->serializer->register_ns("http://microsoft.com/wsdl/mime/textMatching/","tm");
  $self->serializer->register_ns("http://www.aligned-assets.co.uk/SinglePoint/Search/WebServices/V2/SearchServiceInformation","tns");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/soap12/","soap12");
  $self->serializer->register_ns("http://www.w3.org/2001/XMLSchema","s");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/","wsdl");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/soap/encoding/","soapenc");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/mime/","mime");
  $self->serializer->register_ns("http://schemas.xmlsoap.org/wsdl/http/","http");
    my $som = $self->SUPER::call($method => @parameters);
    if ($self->want_som) {
        return $som;
    }
    UNIVERSAL::isa($som => 'SOAP::SOM') ? wantarray ? $som->paramsall : $som->result : $som;
}

sub BEGIN {
    no strict 'refs';
    for my $method (qw(want_som)) {
        my $field = '_' . $method;
        *$method = sub {
            my $self = shift->new;
            @_ ? ($self->{$field} = shift, return $self) : return $self->{$field};
        }
    }
}
no strict 'refs';
for my $method (@EXPORT_OK) {
    my %method = %{$methods{$method}};
    *$method = sub {
        my $self = UNIVERSAL::isa($_[0] => __PACKAGE__)
            ? ref $_[0]
                ? shift # OBJECT
                # CLASS, either get self or create new and assign to self
                : (shift->self || __PACKAGE__->self(__PACKAGE__->new))
            # function call, either get self or create new and assign to self
            : (__PACKAGE__->self || __PACKAGE__->self(__PACKAGE__->new));
        $self->_call($method, @_);
    }
}

sub AUTOLOAD {
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
    return if $method eq 'DESTROY' || $method eq 'want_som';
    die "Unrecognized method '$method'. List of available method(s): @EXPORT_OK\n";
}

1;
