# $Id$

package MT::Plugin::TaggingHelper;

use strict;
use MT::Template::Context;
use MT::Plugin;
@MT::Plugin::TaggingHelper::ISA = qw(MT::Plugin);

use vars qw($PLUGIN_NAME $VERSION);
$PLUGIN_NAME = 'TaggingHelper';
$VERSION = '0.2';

use MT;
my $plugin = new MT::Plugin::TaggingHelper({
    name => $PLUGIN_NAME,
    version => $VERSION,
    description => "<MT_TRANS phrase='description of TaggingHelper'>",
    doc_link => 'http://blog.aklaswad.com/mtplugins/tagginghelper/',
    author_name => 'akira sawada',
    author_link => 'http://blog.aklaswad.com/',
    l10n_class => 'TaggingHelper::L10N',
});

MT->add_plugin($plugin);

my $mt_version = MT->version_number;
if ($mt_version =~ /^4/){
    MT->add_callback('template_param.edit_entry', 9, $plugin, \&hdlr_mt4_param);
}
else {
    MT->add_callback('MT::App::CMS::AppTemplateSource.edit_entry', 9, $plugin, \&hdlr_mt3_source);
}

sub _build_html {
    my $html = <<'EOT';
<style type="text/css">
#tagging_helper_container {
    width: 100%;
}

#tagging_helper_block {
    margin: 10px 0;
    line-height: 1.8em;
}

.taghelper_tag {
    margin: 0 5px;
}

.taghelper_tag_selected {
    margin: 0 5px;
    background-color: #def;
}

</style>

<script type="text/javascript">
var taghelper_ready = 0;
var taghelper_display = 0;
function taghelper_open() {
    var block = document.getElementById('tagging_helper_block');
    if (block.style.display == 'none') {
        block.style.display = 'block';
    }
    else {
        block.style.display = 'none';
    }

    if (taghelper_ready){ return }

    function compareStrAscend(a, b){
        return a.localeCompare(b);
    }
    var tagary = new Array;
    for (var tag in tags ){
        tagary.push(tag);
    }
    
    tagary.sort(compareStrAscend);

    var v = document.getElementById('tags').value;
    for (var i=0; i< tagary.length; i++) {
        var tag = tagary[i];
        var exp = new RegExp("^(.*, ?)?" + tag + "( ?\,.*)?$");
        if (exp.test(v)) {
            block.innerHTML += '<a href="javascript:void(taghelper_action(\'' + tag + '\'))" class="taghelper_tag_selected", id="taghelper_tag_' + tag + '">' + tag + ' </a>';
        }
        else {
            block.innerHTML += '<a href="javascript:void(taghelper_action(\'' + tag + '\'))" class="taghelper_tag", id="taghelper_tag_' + tag + '">' + tag + ' </a>';
        }
    }
        
    taghelper_ready = 1;
}

function taghelper_action(s) {
    var a = document.getElementById('taghelper_tag_' + s);
    
    var v = document.getElementById('tags').value;
    var exp = new RegExp("^(.*, ?)?" + s + "( ?\,.*)?$");
    if (exp.test(v)) {
        v = v.replace(exp, "$1$2");
        if (tag_delim == ',') {
            v = v.replace(/ *, *, */g, ', ');
        }
        else {
            v = v.replace(/  +/g, ' ');
        }
        a.className = 'taghelper_tag';
    }
    else {
        v += (tag_delim == ',' ? ', ' : ' ') + s;
        a.className = 'taghelper_tag_selected';
    }
    v = v.replace(/^[ \,]+/, '');
    v = v.replace(/[ \,]+$/, '');
    document.getElementById('tags').value = v;
}

</script>
<div id="tagging_helper_container">
<a href="javascript: void(taghelper_open())" class="add-new-category-link"><MT_TRANS phrase="old tags"></a>
<div id="tagging_helper_block" style="display: none;"></div>
</div>
EOT
    return $plugin->translate_templatized($html);
}

sub hdlr_mt3_source {
    my ($eh, $app, $tmpl) = @_;
    my $html = _build_html(); 
    my $pattern = quotemeta(<<'EOT');
<input name="tags" id="tags" tabindex="7" value="<TMPL_VAR NAME=TAGS ESCAPE=HTML>" onchange="setDirty()" />
</div>
EOT
    $$tmpl =~ s!($pattern)!$1$html!;
}

sub hdlr_mt4_param {
    my ($eh, $app, $param, $tmpl) = @_;
    my $html = _build_html(); 
    die 'something wrong...' unless UNIVERSAL::isa($tmpl, 'MT::Template');
 
    my $host_node = $tmpl->getElementById('tags')
        or die 'cannot get useful-links block';

    $host_node->innerHTML($host_node->innerHTML . $html);
    1;
}

1;

