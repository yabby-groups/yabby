var Pagenavi = module.exports = React.createClass({
  handleClick: function(evt) {
  },
  render: function() {
    var html = [];
    var limit = this.props.limit || 10;
    var total_page = Math.floor(this.props.total / limit);
    if (total_page * limit < this.props.total) {
      total_page ++;
    }
    var current = this.props.current || 1;
    if (current > 3) {
      html.push(<a className="first" href={config.url + "/"} onClick={this.handleClick}>« 最新</a>);
    }

    if (current == 2) {
      html.push(<a className="prev" href={config.url + "/"} onClick={this.handleClick}>«</a>);
    }

    if (current > 2) {
      html.push(<a className="prev" href={config.url + '/p/' + (current - 1)} onClick={this.handleClick}>«</a>);
    }

    if (current > 3) {
      html.push(<span className="extend">...</span>);
    }

    var start = current - 2;
    var end = current + 2;

    if (start < 1) {
      start = 1;
    }

    if (end > total_page) {
      end = total_page;
    }

    for(var i = start; i <= end; i ++) {
      if (i == current) {
        html.push(<span className="current">{i}</span>)
      } else if (i < current) {
        html.push(<a className="page smaller" href={config.url + "/p/" + i} onClick={this.handleClick}>{i}</a>);
      } else {
        html.push(<a className="page larger" href={config.url + "/p/" + i} onClick={this.handleClick}>{i}</a>);
      }
    }

    if (end < total_page) {
      html.push(<span className="extend">...</span>);
    }

    if (current < total_page) {
      html.push(<a className="next" href={config.url + "/p/" + total_page} onClick={this.handleClick}>»</a>);
    }

    if (end < total_page) {
      html.push(<a className="last" href={config.url + "/p/" + total_page} onClick={this.handleClick}>最旧 »</a>);
    }

    return (
      <div className="pagenavi">
        <span className="pages">{'第' + current + '页，共' + total_page + ' 页'}</span>
        {html}
      </div>
    );
  }
});
