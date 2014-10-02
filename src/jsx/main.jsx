/** @jsx React.DOM */

if (!config) {
  var config = {};
}

var FileItem = React.createClass({
  render: function() {
    var file = this.props.file || {};
    return <img src={config.img_host + '/' + file.file_bucket + '/' + file.file_key} />;
  }
});


var Pagenavi = React.createClass({
  render: function() {
    var html = [];
    var limit = this.props.limit || 10;
    var total_page = Math.floor(this.props.total / limit);
    if (total_page * limit < this.props.total) {
      total_page ++;
    }
    var current = this.props.current || 1;
    if (current > 3) {
      html.push(<a className="first" href="/">« 最新</a>);
    }

    if (current == 2) {
      html.push(<a className="prev" href="/">«</a>);
    }

    if (current > 2) {
      html.push(<a className="prev" href={'/p/' + (current - 1)}>«</a>);
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
        html.push(<a className="page smaller" href={"/p/" + i}>{i}</a>);
      } else {
        html.push(<a className="page larger" href={"/p/" + i}>{i}</a>);
      }
    }

    if (end < total_page) {
      html.push(<span className="extend">...</span>);
    }

    if (current < total_page) {
      html.push(<a className="next" href={"/p/" + total_page}>»</a>);
    }

    if (end < total_page) {
      html.push(<a className="last" href={"/p/" + total_page}>最旧 »</a>);
    }

    return (
      <div className="pagenavi">
        <span className="pages">{'第' + current + '页，共' + total_page + ' 页'}</span>
        {html}
      </div>
    );
  }
});


var TweetItem = React.createClass({
  getInitialState: function() {
    var tweet = this.props.tweet || {};
    var like_count = tweet.like_count || 0;
    var unlike_count = tweet.unlike_count || 0;
    var favorite = 'unfav';
    if (tweet.favorite) {
      favorite = 'fav'
    }
    return {like_count: like_count, unlike_count: unlike_count, favorite: favorite};
  },
  handleLike: function() {
    var self = this;
    $.post("/api/tweets/" + this.props.tweet.tweet_id + '/like', function(data) {
      self.setState(data);
    });
  },
  handleUnLike: function() {
    var self = this;
    $.post("/api/tweets/" + this.props.tweet.tweet_id + '/unlike', function(data) {
      self.setState(data);
    });
  },
  handleFavorite: function() {
    var self = this;
    $.post("/api/tweets/" + this.props.tweet.tweet_id + '/favorite', function(data) {
      self.setState({favorite: "fav"});
    });
  },
  render: function() {
    var tweet = this.props.tweet || {};
    var user = tweet.user || {};

    var file = '';
    if (tweet.file) {
      file = <FileItem file={tweet.file} />;
    }

    return (
      <article className="tweetItem">
        <header className="entry-header">
          <h3 className="entry-title">
            <a href={"/users/" + user.user_id} title={user.username}>{user.username}</a>
          </h3>

          <div className="entry-meta">
            <time className="entry-date">{tweet.created_at + ""}</time>
          </div>
        </header>

        <div className="entry-content clearfix">
          <p>
            {tweet.text}
          </p>
          {file}
        </div>
        <div className="entry-status">
          <span className="like" onClick={this.handleLike}>{this.state.like_count}</span>
          <span className="unlike" onClick={this.handleUnLike}>{this.state.unlike_count}</span>
          <span className={this.state.favorite} onClick={this.handleFavorite}></span>
        </div>
      </article>
    );
  }
});


var TweetList = React.createClass({
  render: function() {
    var tweetNodes = this.props.tweets.map(function(tweet, index) {
      return <TweetItem tweet={tweet} />
    });
    return (
      <div className="tweetList">
      {tweetNodes}
      </div>
    );
  }
});


var TweetBox = React.createClass({
  loadTweetsFromServer: function() {
    var self = this;
    $.get(config.path, function(data) {
      self.setState(data);
    });
  },
  getInitialState: function() {
    return {tweets: [], current: config.current, total: config.total, limit: config.limit};
  },
  componentDidMount: function() {
    this.loadTweetsFromServer();
  },
  render: function() {
    return (
      <div className="container">
        <TweetList tweets={this.state.tweets} />
        <Pagenavi current={this.state.current} total={this.state.total} limit={this.state.limit}/>
      </div>
    );
  }
});


React.renderComponent(
  <TweetBox />,
  document.querySelector("#content")
);


var LoginForm = React.createClass({
  handleSubmit: function(e) {
    e.preventDefault();
    var username = this.refs.username.getDOMNode().value.trim();
    var passwd = this.refs.passwd.getDOMNode().value.trim();
    if (!passwd || !username) {
      return;
    }
    this.props.onLoginSubmit({passwd: passwd, username: username});
    this.refs.username.getDOMNode().value = '';
    this.refs.passwd.getDOMNode().value = '';
    return;
  },
  render: function() {
    return (
      <form className="loginForm" onSubmit={this.handleSubmit}>
        <input type="text" placeholder="username" ref="username" />
        <input type="password" placeholder="password" ref="passwd" />
        <input type="submit" value="登录" />
      </form>
    )
  }
});


var InfoBox = React.createClass({
  handleLogin: function(info) {
    var self = this;
    $.post('/auth', info, function(data) {
      self.setState(data);
    });
  },
  handleLoginOut: function(evt) {
    var self = this;
    evt.defaultPrevented = true;
    $.get('/logout', function() {
      self.setState({user: null});
    });
    return false;
  },
  loadUserInfo: function() {
    var self = this;
    $.get('/api/users/me', function(data) {
      self.setState(data);
    });
  },
  getInitialState: function() {
    return {user: config.user};
  },
  componentDidMount: function() {
    if (!config.user) {
      // this.loadUserInfo();
    }
  },
  render: function() {
    if (!this.state.user || !this.state.user.user_id) {
      return <LoginForm onLoginSubmit={this.handleLogin} />
    }
    return <a href="/logout" onClick={this.handleLoginOut}>{this.state.user.username}</a>
  }
});


React.renderComponent(
  <InfoBox />,
  document.querySelector("#info")
);
