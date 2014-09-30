/** @jsx React.DOM */

var FileItem = React.createClass({
    render: function() {
        var file = this.props.file || {};
        return <img src={'http://huabot.b0.upaiyun.com/tweet/' + file.file_key} />;
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
            html.push(<a className="previouspostslink" href="/">«</a>);
        }

        if (current > 2) {
            html.push(<a className="previouspostslink" href={'/p/' + (current - 1)}>«</a>);
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
            html.push(<a className="nextpostslink" href={"/p/" + total_page}>»</a>);
        }

        if (end < total_page) {
            html.push(<a className="last" href={"/p/" + total_page}>最旧 »</a>);
        }

        return (
            <div className="wp-pagenavi">
                <span className="pages">{'第' + current + '页，共' + total_page + ' 页'}</span>
                {html}
            </div>
        );
    }
});


var TweetItem = React.createClass({
    render: function() {
        var tweet = this.props.tweet || {};
        var user = tweet.user || {};

        var file = '';
        if (tweet.file) {
            file = <FileItem file={tweet.file} />;
        }

        return (
            <article className="post type-post status-publish format-standard hentry">
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
        $.get('/api/tweets', function(data) {
            self.setState(data);
        });
    },
    getInitialState: function() {
        return {tweets: [], current: 1, total: 1};
    },
    componentDidMount: function() {
        this.loadTweetsFromServer();
    },
    render: function() {
        return (
            <div className="container">
                <TweetList tweets={this.state.tweets} />
                <Pagenavi current={this.state.current} total={this.state.total} />
            </div>
        );
    }
});


React.renderComponent(
    <TweetBox />,
   document.querySelector("#content")
);
