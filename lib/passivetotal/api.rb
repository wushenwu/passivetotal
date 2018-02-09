require 'net/http'
require 'net/https'
require 'openssl'
require 'json'
require 'passivetotal/version'

# DESCRIPTION: rubygem for querying PassiveTotal.org's web API

module PassiveTotal # :nodoc:
  
  class InvalidAPIKeyError < ArgumentError; end
  class APIUsageError < StandardError; end
  class ExceededQuotaError < StandardError; end
  
  class Transaction < Struct.new(:query, :response, :response_time); end
  class Query < Struct.new(:api, :query, :set, :url, :parameters); end
  class Response < Struct.new(:json, :success, :results); end
  
  # The API class wraps the PassiveTotal.org web API for all the verbs that it supports
  # See https://api.passivetotal.org/api/docs/ for the API documentation.
  class API
    # The TLDS array helps the interface detect valid domains.
    # This list was generated by parsing the NS records from a zone transfer of the root
    # The same list could have been downloaded from http://data.iana.org/TLD/tlds-alpha-by-domain.txt
    TLDS = "abb,abbott,abogado,ac,academy,accenture,accountant,accountants,active,actor,ad,ads,adult,ae,aeg,aero,af,afl,ag,agency,ai,aig,airforce,al,allfinanz,alsace,am,amsterdam,an,android,ao,apartments,aq,aquarelle,ar,archi,army,arpa,as,asia,associates,at,attorney,au,auction,audio,auto,autos,aw,ax,axa,az,azure,ba,band,bank,bar,barclaycard,barclays,bargains,bauhaus,bayern,bb,bbc,bbva,bd,be,beer,berlin,best,bf,bg,bh,bharti,bi,bible,bid,bike,bing,bingo,bio,biz,bj,black,blackfriday,bloomberg,blue,bm,bmw,bn,bnl,bnpparibas,bo,boats,bond,boo,boutique,br,bradesco,bridgestone,broker,brother,brussels,bs,bt,budapest,build,builders,business,buzz,bv,bw,by,bz,bzh,ca,cab,cafe,cal,camera,camp,cancerresearch,canon,capetown,capital,caravan,cards,care,career,careers,cars,cartier,casa,cash,casino,cat,catering,cba,cbn,cc,cd,center,ceo,cern,cf,cfa,cfd,cg,ch,channel,chat,cheap,chloe,christmas,chrome,church,ci,cisco,citic,city,ck,cl,claims,cleaning,click,clinic,clothing,cloud,club,cm,cn,co,coach,codes,coffee,college,cologne,com,commbank,community,company,computer,condos,construction,consulting,contractors,cooking,cool,coop,corsica,country,coupons,courses,cr,credit,creditcard,cricket,crown,crs,cruises,cu,cuisinella,cv,cw,cx,cy,cymru,cyou,cz,dabur,dad,dance,date,dating,datsun,day,dclk,de,deals,degree,delivery,democrat,dental,dentist,desi,design,dev,diamonds,diet,digital,direct,directory,discount,dj,dk,dm,dnp,do,docs,dog,doha,domains,doosan,download,drive,durban,dvag,dz,earth,eat,ec,edu,education,ee,eg,email,emerck,energy,engineer,engineering,enterprises,epson,equipment,er,erni,es,esq,estate,et,eu,eurovision,eus,events,everbank,exchange,expert,exposed,express,fail,faith,fan,fans,farm,fashion,feedback,fi,film,finance,financial,firmdale,fish,fishing,fit,fitness,fj,fk,flights,florist,flowers,flsmidth,fly,fm,fo,foo,football,forex,forsale,foundation,fr,frl,frogans,fund,furniture,futbol,fyi,ga,gal,gallery,garden,gb,gbiz,gd,gdn,ge,gent,genting,gf,gg,ggee,gh,gi,gift,gifts,gives,gl,glass,gle,global,globo,gm,gmail,gmo,gmx,gn,gold,goldpoint,golf,goo,goog,google,gop,gov,gp,gq,gr,graphics,gratis,green,gripe,gs,gt,gu,guge,guide,guitars,guru,gw,gy,hamburg,hangout,haus,healthcare,help,here,hermes,hiphop,hitachi,hiv,hk,hm,hn,hockey,holdings,holiday,homedepot,homes,honda,horse,host,hosting,hoteles,hotmail,house,how,hr,ht,hu,ibm,icbc,icu,id,ie,ifm,il,im,immo,immobilien,in,industries,infiniti,info,ing,ink,institute,insure,int,international,investments,io,iq,ir,irish,is,it,iwc,java,jcb,je,jetzt,jewelry,jlc,jll,jm,jo,jobs,joburg,jp,juegos,kaufen,kddi,ke,kg,kh,ki,kim,kitchen,kiwi,km,kn,koeln,komatsu,kp,kr,krd,kred,kw,ky,kyoto,kz,la,lacaixa,land,lasalle,lat,latrobe,law,lawyer,lb,lc,lds,lease,leclerc,legal,lgbt,li,liaison,lidl,life,lighting,limited,limo,link,lk,loan,loans,lol,london,lotte,lotto,love,lr,ls,lt,ltda,lu,lupin,luxe,luxury,lv,ly,ma,madrid,maif,maison,management,mango,market,marketing,markets,marriott,mba,mc,md,me,media,meet,melbourne,meme,memorial,men,menu,mg,mh,miami,microsoft,mil,mini,mk,ml,mm,mma,mn,mo,mobi,moda,moe,monash,money,montblanc,mormon,mortgage,moscow,motorcycles,mov,movie,movistar,mp,mq,mr,ms,mt,mtn,mtpc,mu,museum,mv,mw,mx,my,mz,na,nadex,nagoya,name,navy,nc,ne,nec,net,netbank,network,neustar,new,news,nexus,nf,ng,ngo,nhk,ni,nico,ninja,nissan,nl,no,np,nr,nra,nrw,ntt,nu,nyc,nz,office,okinawa,om,omega,one,ong,onl,online,ooo,oracle,org,organic,osaka,otsuka,ovh,pa,page,panerai,paris,partners,parts,party,pe,pf,pg,ph,pharmacy,philips,photo,photography,photos,physio,piaget,pics,pictet,pictures,pink,pizza,pk,pl,place,play,plumbing,plus,pm,pn,pohl,poker,porn,post,pr,praxi,press,pro,prod,productions,prof,properties,property,ps,pt,pub,pw,py,qa,qpon,quebec,racing,re,realtor,recipes,red,redstone,rehab,reise,reisen,reit,ren,rent,rentals,repair,report,republican,rest,restaurant,review,reviews,rich,ricoh,rio,rip,ro,rocks,rodeo,rs,rsvp,ru,ruhr,run,rw,ryukyu,sa,saarland,sale,samsung,sandvik,sandvikcoromant,sap,sarl,saxo,sb,sc,sca,scb,schmidt,scholarships,school,schule,schwarz,science,scor,scot,sd,se,seat,sener,services,sew,sex,sexy,sg,sh,shiksha,shoes,show,shriram,si,singles,site,sj,sk,ski,sky,skype,sl,sm,sn,sncf,so,soccer,social,software,sohu,solar,solutions,sony,soy,space,spiegel,spreadbetting,sr,st,starhub,statoil,study,style,su,sucks,supplies,supply,support,surf,surgery,suzuki,sv,swatch,swiss,sx,sy,sydney,systems,sz,taipei,tatar,tattoo,tax,taxi,tc,td,team,tech,technology,tel,telefonica,temasek,tennis,tf,tg,th,thd,theater,tickets,tienda,tips,tires,tirol,tj,tk,tl,tm,tn,to,today,tokyo,tools,top,toray,toshiba,tours,town,toys,tr,trade,trading,training,travel,trust,tt,tui,tv,tw,tz,ua,ug,uk,university,uno,uol,us,uy,uz,va,vacations,vc,ve,vegas,ventures,versicherung,vet,vg,vi,viajes,video,villas,vision,vista,vistaprint,vlaanderen,vn,vodka,vote,voting,voto,voyage,vu,wales,walter,wang,watch,webcam,website,wed,wedding,weir,wf,whoswho,wien,wiki,williamhill,win,windows,wme,work,works,world,ws,wtc,wtf,xbox,xerox,xin,xn--1qqw23a,xn--30rr7y,xn--3bst00m,xn--3ds443g,xn--3e0b707e,xn--45brj9c,xn--45q11c,xn--4gbrim,xn--55qw42g,xn--55qx5d,xn--6frz82g,xn--6qq986b3xl,xn--80adxhks,xn--80ao21a,xn--80asehdb,xn--80aswg,xn--90a3ac,xn--90ais,xn--9et52u,xn--b4w605ferd,xn--c1avg,xn--cg4bki,xn--clchc0ea0b2g2a9gcd,xn--czr694b,xn--czrs0t,xn--czru2d,xn--d1acj3b,xn--d1alf,xn--estv75g,xn--fiq228c5hs,xn--fiq64b,xn--fiqs8s,xn--fiqz9s,xn--fjq720a,xn--flw351e,xn--fpcrj9c3d,xn--fzc2c9e2c,xn--gecrj9c,xn--h2brj9c,xn--hxt814e,xn--i1b6b1a6a2e,xn--imr513n,xn--io0a7i,xn--j1amh,xn--j6w193g,xn--kcrx77d1x4a,xn--kprw13d,xn--kpry57d,xn--kput3i,xn--l1acc,xn--lgbbat1ad8j,xn--mgb9awbf,xn--mgba3a4f16a,xn--mgbaam7a8h,xn--mgbab2bd,xn--mgbayh7gpa,xn--mgbbh1a71e,xn--mgbc0a9azcg,xn--mgberp4a5d4ar,xn--mgbpl2fh,xn--mgbx4cd0ab,xn--mxtq1m,xn--ngbc5azd,xn--node,xn--nqv7f,xn--nqv7fs00ema,xn--nyqy26a,xn--o3cw4h,xn--ogbpf8fl,xn--p1acf,xn--p1ai,xn--pgbs0dh,xn--q9jyb4c,xn--qcka1pmc,xn--rhqv96g,xn--s9brj9c,xn--ses554g,xn--unup4y,xn--vermgensberater-ctb,xn--vermgensberatung-pwb,xn--vhquv,xn--vuq861b,xn--wgbh1c,xn--wgbl6a,xn--xhq521b,xn--xkc2al3hye2a,xn--xkc2dl3a5ee0h,xn--y9a3aq,xn--yfro4i67o,xn--ygbi2ammx,xn--zfr164b,xxx,xyz,yachts,yandex,ye,yodobashi,yoga,yokohama,youtube,yt,za,zip,zm,zone,zuerich,zw".split(/,/)
    
    # initialize a new PassiveTotal::API object
    # username: the email address associated with your PassiveTotal API key.
    # apikey: is 64-hexcharacter string
    # endpoint: base URL for the web service, defaults to https://api.passivetotal.org/v2/
    def initialize(username, apikey, endpoint = 'https://api.passivetotal.org/v2/')
      unless apikey =~ /^[a-fA-F0-9]{64}$/
        raise ArgumentError.new("apikey must be a 64 character hex string")
      end
      @username = username
      @apikey = apikey
      @endpoint = endpoint
    end
    
    # Account : Get account details your account.
    def account
      get('account')
    end
    
    # Account History : Get history associated with your account.
    def account_history
      get('account/history')
    end
    
    # history is an alias for account_history
    alias_method :history, :account_history
            
    # Account organization : Get details about the organization your account is associated with.
    def account_organization
      get('account/organization')
    end
    
    # organization is an alias for account_organization
    alias_method :organization, :account_organization
    
    # Account organization teamstream : Get the teamstream for the organization your account is associated with.
    def account_organization_teamstream
      get('account/organization/teamstream')
    end
    
    # teamstream is an alias for account_organization_teamstream
    alias_method :teamstream, :account_organization_teamstream
    
    # Account sources : Get source details for a specific source.
    def account_sources(source)
      get('account/sources', {'source' => source})
    end
    
    # sources is an alias for account_sources
    alias_method :sources, :account_sources
    

    # Passive provides a complete passive DNS picture for a domain or IP address including first/last seen values, deconflicted values, sources used, unique counts and enrichment for all values.
    # query: A domain or IP address to query
    def passive(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('dns/passive', {'query' => query})
    end

    # Passive provides a complete passive DNS picture for a domain or IP address including first/last seen values, deconflicted values, sources used, unique counts and enrichment for all values.
    # query: A domain or IP address to query
    def passive_unique(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('dns/passive/unique', {'query' => query})
    end
    
    # unique is an alias for passive_unique
    alias_method :unique, :passive_unique
    
    # Enrichment : Enrich the given query with metadata
    # query: A domain or IP address to query
    def enrichment(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('enrichment', {'query' => query})
    end
    
    # metadata is an alias for enrichment
    alias_method :metadata, :enrichment
    
    # Enrichment bulk : Enrich each of the given queries with metadata
    # query: An array of domains or IP addresses to query
    def bulk_enrichment(query)
      if query.class != Array
        query = [query]
      end
      query.map do |q|
        is_valid_with_error(__method__, [:ipv4, :domain], q)
        if domain?(q)
          q = normalize_domain(q)
        end
        q
      end
      get_with_data('enrichment/bulk', { 'query' => query })
    end

    # osint: Get opensource intelligence data
    # query: A domain or IP address to query
    def osint(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('enrichment/osint', {'query' => query})
    end
    
    # osint bulk : Enrich each of the given queries with metadata
    # query: An array of domains or IP addresses to query
    def bulk_osint(query)
      if query.class != Array
        query = [query]
      end
      query.map do |q|
        is_valid_with_error(__method__, [:ipv4, :domain], q)
        if domain?(q)
          q = normalize_domain(q)
        end
        q
      end
      get_with_data('enrichment/bulk/osint', { 'query' => query })
    end

    # subdomains: Get subdomains using a wildcard query
    # query: A domain with wildcard, e.g., *.passivetotal.org
    def subdomains(query)
      get('enrichment/subdomains', {'query' => query})
    end
      
    # whois: Get WHOIS data for a domain or IP address
    # query: ipv4, domain, or, if you specify a field, any value for that field
    # field: field name to query if not the default ip/domain field
    #   field names: domain, email, name, organization, address, phone, nameserver
    def whois(query, field=nil)
      if field
        is_valid_with_error(__method__, [:whois_field], field)
        get('whois/search', {'field' => field, 'query' => query})
      else
        is_valid_with_error(__method__, [:ipv4, :domain], query)
        if domain?(query)
          query = normalize_domain(query)
        end
        get('whois', {'query' => query, 'compact_record' => 'false'})
      end
    end
        
    # Add a user-tag to an IP or domain
    # query: A domain or IP address to tag
    # tag: Value used to tag query value. Should only consist of alphanumeric, underscores and hyphen values
    def add_tag(query, tag)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      is_valid_with_error(__method__, [:tag], tag)
      post('actions/tags', { 'query' => query, 'tags' => [tag] })
    end
    
    # Remove a user-tag to an IP or domain
    # query: A domain or IP address to remove a tag from
    # tag: Value used to tag query value. Should only consist of alphanumeric, underscores and hyphen values
    def remove_tag(query, tag)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      is_valid_with_error(__method__, [:tag], tag)
      delete('actions/tags', { 'query' => query, 'tags' => [tag] })
    end
    
    # PassiveTotal uses the notion of classifications to highlight table rows a certain color based on how they have been rated.
    # PassiveTotal::API#classification() queries if only one argument is given, and sets if both are given
    # query: A domain or IP address to query
    def classification(query, set=nil)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      if set.nil?
        get('actions/classification', {'query' => query})
      else
        is_valid_with_error(__method__.to_s, [:classification], set)
        post('actions/classification', { 'query' => query, 'classification' => set })
      end
    end
    
    # Get the classification for a query in bulk
    # query: An array of domains or IP address to query
    def bulk_classification(query)
      if query.class != Array
        query = [query]
      end
      query.map do |q|
        is_valid_with_error(__method__, [:ipv4, :domain], q)
        if domain?(q)
          q = normalize_domain(q)
        end
        q
      end
      get_with_data('actions/bulk/classification', { 'query' => query })
    end
    
    # PassiveTotal allows users to notate if a domain or IP address have ever been compromised. These values aid in letting users know that a site may be benign, but it was used in an attack at some point in time.
    # PassiveTotal::API#ever_compromised() queries if only one argument is given, and sets if both are given
    # query: A domain or IP address to query
    # set: a boolean flag
    def ever_compromised(query, set=nil)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      if set.nil?
        get('actions/ever-compromised', {'query' => query})
      else
        is_valid_with_error(__method__, [:bool], set)
        post('actions/ever-compromised', { 'query' => query, 'status' => set })
      end
    end
    
    alias_method :compromised, :ever_compromised
    
    # PassiveTotal allows users to notate if a domain is associated with a dynamic DNS provider.
    # PassiveTotal::API#dynamic() queries if only one argument is given, and sets if both are given
    # query: A domain to query
    # set: a boolean flag
    def dynamic(query, set=nil)
      is_valid_with_error(__method__, [:domain], query)
      query = normalize_domain(query)
      if set.nil?
        get('actions/dynamic-dns', {'query' => query})
      else
        is_valid_with_error(__method__, [:bool], set)
        post('actions/dynamic-dns', { 'query' => query, 'status' => set })
      end
    end
    
    # PassiveTotal allows users to notate if an ip or domain is "monitored".
    # PassiveTotal::API#monitor() queries if only one argument is given, and sets if both are given
    # query: A domain to query
    # set: a boolean flag
    def monitor(query, set=nil)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      if set.nil?
        get('actions/monitor', {'query' => query})
      else
        is_valid_with_error(__method__, [:bool], set)
        post('actions/monitor', { 'query' => query, 'status' => set })
      end
    end
    
    # monitoring is an alias for monitor
    alias_method :monitoring, :monitor
    alias_method :watching, :monitor

    # PassiveTotal allows users to notate if an IP address is a known sinkhole. These values are shared globally with everyone in the platform.
    # PassiveTotal::API#sinkhole() queries if only one argument is given, and sets if both are given
    # query: An IP address to set as a sinkhole or not
    # set: a boolean flag
    def sinkhole(query, set=nil)
      is_valid_with_error(__method__, [:ipv4], query)
      if set.nil?
        get('actions/sinkhole', {'query' => query})
      else
        is_valid_with_error(__method__, [:bool], set)
        post('actions/sinkhole', { 'query' => query, 'status' => set })
      end
    end
    

    # PassiveTotal uses three types of tags (user, global, and temporal) in order to provide context back to the user.
    # query: A domain or IP address to query
    # set: if supplied, adds a tag to an entity
    def tags(query, set=nil)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      if set.nil?
        get('actions/tags', {'query' => query})
      else
        is_valid_with_error(__method__, [:tag], set)
        post('actions/tag', { 'query' => query, 'tags' => [set] })
      end
    end
    
    # Search Tags : Search for items based on tag value
    # PassiveTotal uses three types of tags (user, global, and temporal) in order to provide context back to the user.
    # query: A domain or IP address to query
    def tags_search(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('actions/tags/search', {'query' => query})
    end

    # PassiveTotal collects and provides SSL certificates as an enrichment point when possible. Beyond the certificate data itself, PassiveTotal keeps a record of the IP address of where the certificate was found and the time in which it was collected.
    # query: A SHA-1 hash to query
    def ssl_certificate_history(query)
      is_valid_with_error(__method__, [:ipv4, :hash], query)
      get('ssl-certificate/history', {'query' => query})
    end

    # ssl_certificate: returns details about SSL certificates
    # query: SHA-1 has to query, or, if field is set, a valid value for that field
    # field: the certificate field to query upon
    #  certificate fields: issuer_surname, subject_organizationName, issuer_country, issuer_organizationUnitName, fingerprint, subject_organizationUnitName, serialNumber, subject_emailAddress, subject_country, issuer_givenName, subject_commonName, issuer_commonName, issuer_stateOrProvinceName, issuer_province, subject_stateOrProvinceName, sha1, sslVersion, subject_streetAddress, subject_serialNumber, issuer_organizationName, subject_surname, subject_localityName, issuer_streetAddress, issuer_localityName, subject_givenName, subject_province, issuer_serialNumber, issuer_emailAddress
    def ssl_certificate(query, field=nil)
      if field.nil?
        is_valid_with_error(__method__, [:hash], query)
        get('ssl-certificate', {'query' => query})
      else
        is_valid_with_error(__method__, [:ssl_field], field)
        get_params('ssl-certificate/search', { 'query' => query, 'field' => field })
      end
    end
    
    # PassiveTotal tracks some interesting metadata about a host
    # query: a hostname or ip address
    def components(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('host-attributes/components', {'query' => query})
    end
    
    # trackers: Get all tracking codes for a domain or IP address.
    # query: ip or domain, or, if type is supplied, a valid tracker ID
    # type: A valid tracker type to search:
    #   tracker types: YandexMetricaCounterId, ClickyId, GoogleAnalyticsAccountNumber, NewRelicId, MixpanelId, GoogleAnalyticsTrackingId
    def trackers(query, type=nil)
      if type.nil?
        is_valid_with_error(__method__, [:ipv4, :domain], query)
        if domain?(query)
          query = normalize_domain(query)
        end
        get('host-attributes/trackers', {'query' => query})
      else
        is_valid_with_error(__method__, [:tracker_type], type)
        get('trackers/search', {'query' => query, 'type' => type})
      end
    end
    
    # malware: get sample information based from domain
    # query: ip or domain
    def malware(query)
      is_valid_with_error(__method__, [:ipv4, :domain], query)
      if domain?(query)
        query = normalize_domain(query)
      end
      get('enrichment/malware', {'query' => query})
    end
    
    # malware bulk: get sample information based from domains
    # query: An array of domains or IP addresses to query
    def bulk_malware(query)
      if query.class != Array
        query = [query]
      end
      query.map do |q|
        is_valid_with_error(__method__, [:ipv4, :domain], q)
        if domain?(q)
          q = normalize_domain(q)
        end
        q
      end
      get_with_data('enrichment/bulk/malware', { 'query' => query })
    end
    
 
    private
    
    # returns true if the given string is a dotted quad IPv4 address
    def ipv4?(ip)
      if ip =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
        return true
      end
      false
    end
    
    # returns true if the given string looks like a domain and ends with a known top-level domain (TLD)
    def domain?(domain)
      return false if domain.nil?
      domain = normalize_domain(domain)
      domain =~ /^[a-zA-Z0-9\-\.]{3,255}$/ and TLDS.index(domain.split(/\./).last)
    end
    
    # returns true if the given string looks like a SHA-1 hash, i.e., 40 character hex string
    def hash?(hash)
      return false if hash.nil?
      if hash =~ /^[a-fA-F0-9]{40}$/
        return true
      end
      false
    end
    
    # returns true if the given string matches a valid classification
    def classification?(c)
      not ["malicious", "non-malicious", "suspicious", "unknown"].index(c).nil?
    end
    
    # returns true is the given object matches true or false
    def bool?(b)
      not ['true', 'false'].index(b.to_s).nil?
    end
    
    # returns true if the given string looks like a valid tag
    def tag?(t)
      return false if t.nil?
      if t =~ /^[a-zA-Z][\w\_\-]+[a-zA-Z]$/
        return true
      end
      false
    end
    
    def ssl_field?(f)
      return false if f.nil?
      not ["issuerSurname", "subjectOrganizationName", "issuerCountry", "issuerOrganizationUnitName", 
        "fingerprint", "subjectOrganizationUnitName", "serialNumber", "subjectEmailAddress", "subjectCountry", 
        "issuerGivenName", "subjectCommonName", "issuerCommonName", "issuerStateOrProvinceName", "issuerProvince", 
        "subjectStateOrProvinceName", "sha1", "sslVersion", "subjectStreetAddress", "subjectSerialNumber", 
        "issuerOrganizationName", "subjectSurname", "subjectLocalityName", "issuerStreetAddress", 
        "issuerLocalityName", "subjectGivenName", "subjectProvince", "issuerSerialNumber", "issuerEmailAddress"].index(f).nil?
    end
    
    def whois_field?(f)
      return false if f.nil?
      not ["domain", "email", "name", "organization", "address", "phone", "nameserver"].index(f).nil?
    end
    
    def tracker_type?(t)
      return false if t.nil?
      not ["YandexMetricaCounterId", "ClickyId", "GoogleAnalyticsAccountNumber", "NewRelicId", "MixpanelId", "GoogleAnalyticsTrackingId"].index(t).nil?
    end
    
    # lowercases and removes a trailing period (if one exists) from a domain name
    def normalize_domain(domain)
      return domain.downcase.gsub(/\.$/,'')
    end

    # helper function to perform an HTTP GET against the web API
    def get(api, params={})
      url2json(:GET, "#{@endpoint}#{api}", params)
    end
 
    # helper function to perform an HTTP GET against the web API
    def get_params(api, params)
      url2json(:GET, "#{@endpoint}#{api}", params)
    end
    
    def get_with_data(api, params={})
      url2json(:GET_DATA, "#{@endpoint}#{api}", params)
    end
    
    # helper function to perform an HTTP POST against the web API
    def post(api, params)
      url2json(:POST, "#{@endpoint}#{api}", params)
    end
    
    # helper function to perform an HTTP DELETE against the web API
    def delete(api, params)
      url2json(:DELETE, "#{@endpoint}#{api}", params)
    end
    
    # main helper function to perform HTTP interactions with the web API.
    def url2json(method, url, params)
      if method == :GET
        url << "?" + params.map{|k,v| "#{k}=#{v}"}.join("&")
      end
			url = URI.parse url
			http = Net::HTTP.new(url.host, url.port)
			http.use_ssl = (url.scheme == 'https')
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			http.verify_depth = 5
      request = nil
      if method == :GET
        request = Net::HTTP::Get.new(url.request_uri)
      elsif method == :GET_DATA
        request = Net::HTTP::Get.new(url.request_uri)
        form_data = params.to_json
        request.content_type = 'application/json'
        request.body = form_data
      elsif method == :POST
        request = Net::HTTP::Post.new(url.request_uri)
        form_data = params.to_json
        request.content_type = 'application/json'
        request.body = form_data
      elsif method == :DELETE
        request = Net::HTTP::Delete.new(url.request_uri)
        form_data = params.to_json
        request.content_type = 'application/json'
        request.body = form_data
      elsif method == :HEAD
        request = Net::HTTP::Head.new(url.request_uri)
        request.set_form_data(params)
      elsif method == :PUT
        request = Net::HTTP::Put.new(url.request_uri)
        request.set_form_data(params)
      end
      request.basic_auth(@username, @apikey)
      request.add_field("User-Agent", "Ruby/#{RUBY_VERSION} passivetotal rubygem v#{PassiveTotal::VERSION}")
			t1 = Time.now
			response = http.request(request)
			delta = (Time.now - t1).to_f
      data = JSON.parse(response.body)
      
      obj = Transaction.new(
        Query.new(method, params['query'], params[method] || params['tag'], url, params),
        Response.new(response.body, response.code == '200', data),
        delta
      )
      
      if data['error']
        message = data['error']['message']
        case message
        when "API key provided does not match any user."
          raise InvalidAPIKeyError.new(obj)
        when "Quota has been exceeded!"
          raise ExceededQuotaError.new(obj)
        else
          raise APIUsageError.new(obj)
        end
      end

      return obj
    end
    
    # tests an item to see if it matches a valid type
    def is_valid?(types, item)
      types.each do |type|
        if type == :ipv4
          return true if ipv4?(item)
        elsif type == :domain
          return true if domain?(item)
        elsif type == :hash
          return true if hash?(item)
        elsif type == :classification
          return true if classification?(item)
        elsif type == :tag
          return true if tag?(item)
        elsif type == :bool
          return true if bool?(item)
        elsif type == :ssl_field
          return true if ssl_field?(item)
        elsif type == :whois_field
          return true if whois_field?(item)
        elsif type == :tracker_type
          return true if tracker_type?(item)
        end
      end
      return false
    end
    
    # tests an item to see if it matches a valid type and raises an ArgumentError if invalid
    def is_valid_with_error(methname, types, item)
      valid = is_valid?(types, item)
      unless valid
        raise ArgumentError.new("#{methname} requires arguments of type: #{types.join(",")}")
      end
      valid
    end

  end
end