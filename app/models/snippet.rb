include ActionView::Helpers::TextHelper

class Snippet < ActiveRecord::Base

    belongs_to :source
    belongs_to :word

    require 'net/http'

    @@access_token = ENV['LIB_AUTH_TOKEN']
    @@expiration =  1395202753

    def fetch(word, page = 1)

        self.refresh_token() if @@expiration <= Time.new.to_i

        uri = URI.parse("https://www.googleapis.com/books/v1/volumes?q=#{word}&libraryRestrict=my-library&start-index=#{(page - 1) * 40}&key=#{ENV['GOOGLE_PUBLIC_KEY']}&access_token=#{@@access_token}")

        # puts uri.request_uri

        # puts uri.host
        # puts uri.port
        # puts uri.path.to_s

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        self.parse_response(JSON.parse(response.body), word.downcase, page)
    end

    def refresh_token

        # puts "refresh me"

        client_id = ENV['GOOGLE_CLIENT_ID']
        client_secret = ENV['GOOGLE_CLIENT_SECRET']
        scope = "https://www.googleapis.com/auth/books"

        http = Net::HTTP.new('accounts.google.com', 443)
        http.use_ssl = true
        path = '/o/oauth2/token'

        data = "client_id=#{client_id}&client_secret=#{client_secret}&refresh_token=#{ENV['LIB_REFRESH_TOKEN']}&grant_type=refresh_token"

        headers = { 'Content-Type' => 'application/x-www-form-urlencoded'}

        resp, data = http.post(path, data, headers)
        resp_body = JSON.parse(resp.body)

        # puts resp_body

        @@access_token = resp_body['access_token']

        @@expiration = resp_body['expires_in'].to_i + Time.new.to_i
    end

    def parse_response(response, search_word, page)
        return unless response && response['items']
        word = Word.find_or_create_by(body: search_word)
        response['items'].each do |book|
            next if book['volumeInfo']['description'][0..10] == book['searchInfo']['textSnippet'][0..10]
            author = Author.find_by name: book['volumeInfo']['authors'][0]
            author ||=  Author.create({name: book['volumeInfo']['authors'][0]})
            source = Source.find_by title: book['volumeInfo']['title'] 
            source ||= author.sources.create({
                :title => book['volumeInfo']['title'],
                :isbn => book['volumeInfo']['industryIdentifiers'][0]['identifier'],
                :google_id => book['id']
            })
            next if source.words.find_by(body: search_word)
            decoded_body = Nokogiri::HTML(book['searchInfo']['textSnippet']).text.gsub("\n", "")
            word.snippets << source.snippets.find_or_create_by(body: decoded_body)
        end
        self.fetch(word, page + 1) if response['items'].length > 40 
    end

    def fetch_list

        some_words = "abate,abbreviate,aberrant,aberration,abet,abhor,ablution,abominable,abortive,abridge,abrogate,abscond,abstemious,abstinent,abstain,abstruse,accede,acclaim,accolade,accoutre,accretion,acerbic,acidulous,acme,acquiesce,acolyte,acrimonious,acrimony,actuate,acumen,adamant,adulterate,aeon,aesthetic,aggrandize,alacrity,alchemy,alchemist,alliteration,amalgamate,ameliorate,amelioration,amenable,anachronism,anachronistic,analogous,anarchy,animus,annihilate,annotate,anomalous,anomally,anomaly,anomalous,antecede,antipathy,antithesis,antithetic,aplomb,apocryphal,apostate,apathy,ape,apex,appellation,approbation,arbiter,arcane,array,ascetic,asperity,asperse,aspersion,assay,assuage,astringent,audacious,audacity,augment,augur,austere,avarice,aver,axiom,axiomatic,Bacchanalia,bacchanalian,bacchantic,bacchic,bacchant,baleful,banal,banality,baneful,bellicose,bereave,bombastic,bombast,bountiful,brook,bucolic,burgeoning,burgeon,buttress,cacophony,callow,calumny,cajole,canon,canonical,capricious,carnage,carping,castigate,castigation,catalyst,catechism,catholic,caustic,celerity,censure,chary,chicanery,churlish,circumlocution,climactic,cloy,coda,cogent,cognizant,cohere,culpability,colloquy,commensurate,compendium,compilation,complaisant,complaisance,compliant,conciliatory,concordat,confer,conformity,conjoin,connoisseur,contentious,contingent,contrite,conundrum,conventional,convention,convoluted,copious,correlate,corroborate,corroboration,counterpart,covert,craven,credulous,culpable,cupidity,curmudgeon,curtail,cynicism,dally,dearth,debacle,debase,debonair,declivity,debauchery,decorum,decorous,defer,deference,deference,deleterious,deliberate,demur,deplete,deposition,depraved,depravity,derelict,derision,derivative,descant,desiccate,desiccation,detriment,diatribe,didactic,diffident,diffidence,diffuse,dilate,dilatory,dilettante,disabuse,discernible,disconsolate,discordant,discourse,discrete,discretion,disinterested,dismember,disparage,disparate,dispersion,disputatious,dissemble,dissipated,dissipation,dissonant,dissonance,diurnal,divulge,doggerel,dogma,dogmatic,dogmatism,dogmatic,dubious,duplicity,ebullience,eclectic,ecstasy,edify,effete,efficacy,efficacious,effluvium,effrontery,elegy,elucidate,emollient,empirical,emulate,encomium,encompass,encumber,endemic,enervate,engender,engrossed,enigma,enigmatic,ennui,ephemeral,epic,epitome,epoch,equivocal,equivocate,equivocation,equivocate,ersatz,erudite,erudition,erudition,esoteric,espouse,estheticism,eulogy,eulogize,evanescent,exacerbate,excoriate,exculpate,execrable,exegesis,exhaustive,exigent,exonerate,exorbitant,expatiate,expediency,explication,exposition,extemporaneous,extol,exuberant,fabricate,facetious,facile,fallacious,fallacy,fancied,fanciful,fatalism,fatuous,fawn,fawning,fecund,fecundity,feign,fervent,fester,festering,festor,fetid,filibuster,finesse,flag,flay,florid,flout,fluster,forbear,forbearance,fortuitous,frenetic,frieze,froward,fulminate,fulsome,furtive,fusillade,fusilladed,fusillading,futile,gainsay,galvanize,gape,garner,garrulity,garrulous,gaunt,genial,genre,germane,gerrymander,ghastly,gingerly,glib,glutinous,goad,gossamer,gourmand,grandiloquent,gratuitous,gregarious,grotesque,guffaw,guile,guileless,gustatory,gusto,hackneyed,haggard,halcyon,hamper,haphazard,hapless,harangue,harping,harrowing,haughtiness,hedonism,hegemony,heretic,hiatus,hierarchy,hubris,hyperbole,hypocritical,hypothetical,iconoclastic,iconoclast,ideology,idiom,idolatrous,idyllic,ignominious,imbroglio,immune,immutable,impervious,impalpable,impassive,impeccable,impecunious,impediment,impermeable,imperturbable,impetuous,impinge,implacable,implausible,impolitic,improvident,impudent,impropriety,imprudent,impugn,impunity,inadvertence,inarticulate,inchoate,incipient,incisive,incoherence,incontrovertible,incorrigible,incredulous,inculcate,incumbent,indifferent,indignant,indolence,indubitably,ineffable,ineluctable,inept,inert,inexorable,inference,infirmity,infelicitous,ingenuous,inimical,iniquity,injurious,innocuous,inordinate,inscrutable,insidious,insipid,insouciant,intractable,intransigent,intrepid,inured,inure,invective,inveigh,inveigle,interregnum,interrex,invidious,irascible,irksome,jactation,jactitation,jaundiced,jejune,jetsam,jingoism,juxtapose,kalology,kilter,kindred,kinematic,knavery,laconic,languid,languish,lambaste,latency,latent,laud,laudable,laudatory,laudatory,lecherous,levity,libertine,libidinous,licentious,lieu,linguistic,loquacious,lucid,lugubrious,luminous,lymphatic,magnanimity,magnanimous,magnate,malaise,malevolent,malicious,malleable,manifest,marshal,martial,materiel,maverick,meddlesome,meditation,melancholy,mellifluous,mendacious,mendacity,mercurial,metamorphosis,metaphor,meticulous,miasma,mien,migratory,mimicry,minatory,misanthrope,misanthropic,miscellany,misconstrue,misogamy,mitigate,mitigation,mnemonic,mogul,moiety,mollify,monarchy,monotheism,moot,mordant,mordacious,mores,moribund,morose,motility,muddle,multifarious,mundane,munificent,mutinous,myriad,nadir,nascent,nebulous,neologism,neophyte,nepotism,niggle,nihilism,noisome,nonage,nonchalance,notorious,novice,noxious,nugatory,obdurate,obfuscate,objurgate,obliquity,obliterate,obloquy,obscure,obsequious,obsolete,obstinate,obstreperous,obtuse,obviate,occlude,occlusion,odious,olfactory,oligarchy,omnipotent,onomatopoeia,ontology,opaque,opprobrium,oratorio,oscillate,oscillation,ossify,ostentatious,oust,overt,overweening,paean,pacifist,palatable,palliate,palpable,panegyric,pantomime,parable,paradox,parody,pastoral,paucity,pedagogue,pedagogy,pedantic,pedestrian,pejorative,penchant,penurious,penury,perennial,perfidious,perfidy,perfidious,perfunctory,periphrastic,periphrasis,permeable,permeate,pernicious,peroration,perspicacious,perspicuity,pertinacious,pertinent,peruse,pervade,pervasive,petulant,phlegmatic,pique,pillory,pine,pious,piquant,pirate,pith,pithy,placate,platitude,plauditory,plenary,plenitude,plethora,plumb,plummet,polemic,polemical,potent,pragmatic,prattle,preamble,precipitate,precursor,predilection,preen,prefatory,preposterous,prescience,presumptuous,prevaricate,prevarication,pristine,probity,proclivity,prodigal,prodigious,profligate,profundity,profuse,prognosticate,proliferate,proliferation,prolific,prolix,promiscuous,propensity,propinquity,propitiate,prosaic,proselyte,proselytize,puissance,pungent,pusillanimous,putrefy,quaff,qualm,quandary,querulous,query,quiescence,quiescent,quixotic,quorum,quotidian,ramification,rancorous,rapprochement,rarefy,rarefied,rarefaction,rebuke,recalcitrant,recapitulate,recant,refutation,reciprocal,recondite,recreant,redoubtable,refractory,refulgent,refute,relegate,reminiscence,remonstrate,remunerative,renaissance,renascence,renege,renitent,repertoire,reprobate,reprobation,reprove,repudiate,repugnant,rescind,resolute,restive,reticent,retrospective,reverent,rhetoric,ribald,rivet,ruddy,rusticate,sagacious,salacious,salubrious,salutary,sanction,sanguine,sapient,satiate,satire,satiric,saturnine,savor,scupper,scurrilous,sedulous,sequester,serendipity,servile,shibboleth,sinuous,sobriety,solicitous,soporific,sordid,sparse,specious,speciousness,spendthrift,sporadic,spurious,squalid,static,sterile,stoic,stultify,stupefy,stymie,subaltern,subjugate,subtle,succinct,sullen,superfluous,supercilious,supplant,suppress,suppurating,suppurate,supperation,surfeit,surreptitious,synthesis,tacit,taciturn,tantamount,taut,tautological,temerity,temerarious,tenacity,tenuous,terse,timbre,timorous,tirade,torpid,torque,tortuous,tout,tractable,transgression,transient,transitory,transmute,trenchant,trepidation,trite,truculent,turbid,turgid,turpitude,tutelary,tyro,ubiquitous,ulterior,unconscionable,unfaltering,unfeigned,unfettered,unfledged,uniformity,unprecedented,untenable,untoward,urbane,usurpation,vacillate,vacuous,vainglorious,variegated,vapid,vehement,venerate,veneration,veracity,verbose,vernacular,vex,vexation,viable,vigilant,vilify,vindicate,vindictive,virulent,viscous,vitiate,vituperate,volatile,volition,voluptuous,vulnerable,voracious,wane,wangle,welter,wheedle,whet,winnow,winsome,xanthic,xenophobia,xenophobe,xyloid,yammer,yoke,zealot,zealous,zymotic,New Oxford American Dictionary"
        word_array = some_words.split(',')
        mini_word_array = word_array[161..170]
        mini_word_array.concat self.analyze_words(mini_word_array)
        mini_word_array.each do |word|
            self.fetch(word)
            # self.fetch(Verbs::Conjugator.conjugate word.to_sym, :tense => :past, :person => :second, :plurality => :singular, :aspect => :perfective)
        end
    end

    def analyze_words(words_array)
        words = words_array.join(' ')

        uri = URI.parse('http://api.textrazor.com/')

        http = Net::HTTP.new(uri.host, uri.port)
        http.set_debug_output($stdout)
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({"text" => words, "apiKey" => ENV['TEXT_RAZOR_KEY'], "extractors" => "words"})

        resp, data = http.request(request)
        resp_body = JSON.parse(resp.body)

        extra_word_forms = []

        puts resp_body

        resp_body['response']['sentences'][0]['words'].each do |word_obj|
            case word_obj['partOfSpeech']
                # Noun Singular
                when 'NN'
                    word = word_obj['token']
                    extra_word_forms << word.pluralize(2)
                    extra_word_forms << word.pluralize(3) if word.pluralize(2) != word.pluralize(3)
                # Noun Plural
                when 'NNS'
                    word = word_obj['token']
                    extra_word_forms << word.singularize
                end
        end
        return extra_word_forms
    end

    # wordPast = Verbs::Conjugator.conjugate :abate, :tense => :past, :person => :second, :plurality => :singular, :aspect => :perfective

    #     self.fetch(word) if wordPast
end
